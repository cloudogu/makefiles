static-analysis: ${GOPATH}/bin/reviewdog static-analysis-${ENVIRONMENT}

static-analysis-ci: target/static-analysis-cs.log
	@if [ X"$${CI_PULL_REQUEST}" != X"" -a X"$${CI_PULL_REQUEST}" != X"null" ] ; then cat $< | CI_COMMIT=$(COMMIT_ID) reviewdog -f=checkstyle -ci="common" ; fi

static-analysis-local: target/static-analysis-cs.log target/static-analysis.log
	@echo ""
	@echo "differences to develop branch:"
	@echo ""
	@cat $< | reviewdog -f checkstyle -diff "git diff develop"

target/static-analysis.log:
	@mkdir -p ${TARGET_DIR}
	@echo ""
	@echo "complete static analysis:"
	@echo ""
	@$(LINT) ${LINTFLAGS} ./... | tee $@

target/static-analysis-cs.log:
	@mkdir -p ${TARGET_DIR}
	@$(LINT) ${LINTFLAGS} --checkstyle ./... > $@ | true

${GOPATH}/bin/reviewdog:
	go get -u github.com/haya14busa/reviewdog/cmd/reviewdog
