# build steps: dependencies, compile, package
#
# XXX dependencies- target can not be associated to a file.
# As a consequence make build will always trigger a full build, even if targets already exist.
#

UID_NR:=$(shell id -u)
GID_NR:=$(shell id -g)
GLIDE=glide
GLIDEFLAGS=
LDFLAGS=-ldflags "-extldflags -static -X main.Version=$(VERSION) -X main.CommitID=$(COMMIT_ID)"
BUILDDIR=$(WORKDIR)/build
TMPDIR=$(BUILDDIR)/tmp
HOMEDIR=$(TMPDIR)/home
PASSWD=$(TMPDIR)/passwd


ifeq ($(ENVIRONMENT), ci)
	GLIDEFLAGS+=--no-color
endif

.PHONY: info
info:
	@echo "dumping build information ..."
	@echo "Version    : $(VERSION)"
	@echo "Snapshot   : $(SNAPSHOT)"
	@echo "Commit-ID  : $(COMMIT_ID)"
	@echo "Environment: $(ENVIRONMENT)"
	@echo "Branch     : $(BRANCH)"
	@echo "Branch-Type: $(BRANCH_TYPE)"
	@echo "Packages   : $(PACKAGES)"

package: $(TARGET_DIR)/$(ARTIFACT_ID)
	cd $(TARGET_DIR) && tar cvzf $(ARTIFACT_ID)-$(VERSION).tar.gz $(ARTIFACT_ID)

.PHONY: compile
compile: $(TARGET_DIR)/$(ARTIFACT_ID) $(TARGET_DIR)/$(ARTIFACT_ID).sha256sum

$(TMPDIR): $(BUILDDIR)
	mkdir $(TMPDIR)

$(TARGET_DIR):
	mkdir $(TARGET_DIR)

$(HOMEDIR): $(TMPDIR)
	mkdir $(HOMEDIR)

$(PASSWD): $(TMPDIR)
	echo "$(USER):x:$(UID_NR):$(GID_NR):$(USER):/home/$(USER):/bin/bash" > $(PASSWD)

$(TARGET_DIR)/$(ARTIFACT_ID): update-dependencies $(PASSWD) $(HOMEDIR) $(TARGET_DIR)
	docker run --rm -ti \
	 -e GOOS=linux \
	 -e GOARCH=amd64 \
	 -u "$(UID_NR):$(GID_NR)" \
	 -v $(PASSWD):/etc/passwd:ro \
	 -v $(HOMEDIR):/home/$(USER) \
	 -v $(WORKDIR):/go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 -w /go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 cloudogu/golang:1.10 \
go build -a -tags netgo $(LDFLAGS) -installsuffix cgo -o $(TARGET_DIR)/$(ARTIFACT_ID)


$(TARGET_DIR)/$(ARTIFACT_ID).sha256sum:
	cd $(TARGET_DIR); shasum -a 256 $(ARTIFACT_ID) > $(ARTIFACT_ID).sha256sum

#$(TARGET_DIR)/$(ARTIFACT_ID).asc:
#	gpg --detach-sign -o $(TARGET_DIR)/$(ARTIFACT_ID).asc $(TARGET_DIR)/$(ARTIFACT_ID)
