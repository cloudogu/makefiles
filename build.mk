# build steps: dependencies, compile, package
#
# XXX dependencies- target can not be associated to a file.
# As a consequence make build will always trigger a full build, even if targets already exist.
#
info:
	@echo "dumping build information ..."
	@echo "Version    : $(VERSION)"
	@echo "Snapshot   : $(SNAPSHOT)"
	@echo "Build-Time : $(BUILD_TIME)"
	@echo "Commit-ID  : $(COMMIT_ID)"
	@echo "Environment: $(ENVIRONMENT)"
	@echo "Branch     : $(BRANCH)"
	@echo "Branch-Type: $(BRANCH_TYPE)"
	@echo "Packages   : $(PACKAGES)"

dependencies: info
	@echo "installing dependencies ..."
	${GLIDE} ${GLIDEFLAGS} install -v

${EXECUTABLE}: dependencies
	@echo "compiling ..."
	mkdir -p $(COMPILE_TARGET_DIR)
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -tags netgo ${LDFLAGS} -o $@
	@echo "... executable can be found at $@"

${PACKAGE}: ${EXECUTABLE}
	cd ${COMPILE_TARGET_DIR} && tar cvzf ${ARTIFACT_ID}-v${VERSION}.tar.gz ${ARTIFACT_ID}

build: ${PACKAGE}
