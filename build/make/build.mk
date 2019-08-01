# build steps: dependencies, compile, package
#
# XXX dependencies- target can not be associated to a file.
# As a consequence make build will always trigger a full build, even if targets already exist.
#

UID_NR:=$(shell id -u)
GID_NR:=$(shell id -g)
LDFLAGS=-ldflags "-extldflags -static -X main.Version=$(VERSION) -X main.CommitID=$(COMMIT_ID)"
BUILDDIR=$(WORKDIR)/build
HOMEDIR=$(TMP_DIR)/home
PASSWD=$(TMP_DIR)/passwd
GOIMAGE?=cloudogu/golang
GOTAG?=1.10.2-2
GOOS?=linux
GOARCH?=amd64

.PHONY: compile
compile: $(BINARY)

$(TMP_DIR):
	@mkdir $(TMP_DIR)

$(HOMEDIR): $(TMP_DIR)
	@mkdir $(HOMEDIR)

$(PASSWD): $(TMP_DIR)
	@echo "$(USER):x:$(UID_NR):$(GID_NR):$(USER):/home/$(USER):/bin/bash" > $(PASSWD)

compile-generic:
	@echo "Compiling..."
	@go build -a -tags netgo $(LDFLAGS) -installsuffix cgo -o $(BINARY)


ifeq ($(ENVIRONMENT), ci)

$(BINARY): $(SRC) vendor
	@echo "Built on CI server"
	@make compile-generic

else

$(BINARY): $(SRC) vendor $(PASSWD) $(HOMEDIR)
	@echo "Building locally (in Docker)"
	@docker run --rm \
	 -e GOOS=$(GOOS) \
	 -e GOARCH=$(GOARCH) \
	 -u "$(UID_NR):$(GID_NR)" \
	 -v $(PASSWD):/etc/passwd:ro \
	 -v $(HOMEDIR):/home/$(USER) \
	 -v $(WORKDIR):/go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 -w /go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 $(GOIMAGE):$(GOTAG) \
  make compile-generic

endif
