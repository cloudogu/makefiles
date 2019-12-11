# This is a phony target because otherwise the go-junit-report file may be older than the dependent integration-test.xml
# which leads to a non-execution of the actual ${XUNIT_INTEGRATION_XML} target.
.PHONY: ${GOPATH}/bin/go-junit-report
${GOPATH}/bin/go-junit-report:
	@${GO_CALL} get -u github.com/jstemmer/go-junit-report
