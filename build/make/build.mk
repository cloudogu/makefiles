# build steps: dependencies, compile, package
#
# XXX dependencies- target can not be associated to a file.
# As a consequence make build will always trigger a full build, even if targets already exist.
#


LDFLAGS=-ldflags "-extldflags -static -X main.Version=$(VERSION) -X main.CommitID=$(COMMIT_ID)"

.PHONY: compile
compile: $(TARGET_DIR)/$(ARTIFACT_ID)

compile-generic:
	@echo "Compiling..."
	@go build -a -tags netgo $(LDFLAGS) -installsuffix cgo -o $(TARGET_DIR)/$(ARTIFACT_ID)

compile-ci: dependencies $(PASSWD) $(HOMEDIR) $(TARGET_DIR) compile-generic
	@echo "Built on CI server"

compile-local: dependencies $(PASSWD) $(HOMEDIR) $(TARGET_DIR) $(PRE_COMPILE)
	@echo "Building locally (in Docker)"
	@docker run --rm \
	 -e GOOS=linux \
	 -e GOARCH=amd64 \
	 -u "$(UID_NR):$(GID_NR)" \
	 -v $(PASSWD):/etc/passwd:ro \
	 -v $(HOMEDIR):/home/$(USER) \
	 -v $(WORKDIR):/go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 -w /go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 cloudogu/golang:1.10.2 \
  make compile-generic


$(TARGET_DIR)/$(ARTIFACT_ID): dependencies $(PASSWD) $(HOMEDIR) $(TARGET_DIR)
ifeq ($(ENVIRONMENT), ci)
  $(TARGET_DIR)/$(ARTIFACT_ID): compile-ci
else
  $(TARGET_DIR)/$(ARTIFACT_ID): compile-local
endif
