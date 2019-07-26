TARGETDIR=target
LINT=$(GOPATH)/bin/golangci-lint
# ignore tests and mocks
LINTFLAGS=--tests=false --skip-files="^.*_mock.go$$" --skip-files="^.*/mock.*.go$$"

.PHONY: static-analysis
static-analysis: $(GOPATH)/bin/reviewdog static-analysis-$(ENVIRONMENT)

.PHONY: static-analysis-ci
static-analysis-ci: target/static-analysis-cs.log
	@if [ X"$$(CI_PULL_REQUEST)" != X"" -a X"$$(CI_PULL_REQUEST)" != X"null" ] ; then cat $< | CI_COMMIT=$(COMMIT_ID) reviewdog -f=checkstyle -ci="common" ; fi

.PHONY: static-analysis-local
static-analysis-local: target/static-analysis-cs.log target/static-analysis.log
	@echo ""
	@echo "differences to develop branch:"
	@echo ""
	@cat $< | $(GOPATH)/bin/reviewdog -f checkstyle -diff "git diff develop"

$(LINT): 
	@go get -u github.com/golangci/golangci-lint/cmd/golangci-lint

target/static-analysis.log: $(LINT)
	@mkdir -p $(TARGETDIR)
	@echo ""
	@echo "complete static analysis:"
	@echo ""
	@$(LINT) $(LINTFLAGS) run ./... | tee $@

target/static-analysis-cs.log: $(LINT)
	@mkdir -p $(TARGETDIR)
	@$(LINT) $(LINTFLAGS) run --out-format=checkstyle ./... > $@ | true

$(GOPATH)/bin/reviewdog:
	@go get -u github.com/haya14busa/reviewdog/cmd/reviewdog
