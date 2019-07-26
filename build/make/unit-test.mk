XUNIT_XML=$(TARGET_DIR)/unit-tests.xml
COVERAGE_REPORT=$(TARGET_DIR)/coverage.out

PRE_UNITTESTS?=
POST_UNITTESTS?=

.PHONY: unit-test
unit-test: $(PRE_UNITTESTS) ${XUNIT_XML} $(POST_UNITTESTS)

${XUNIT_XML}: ${GOPATH}/bin/go-junit-report
	@mkdir -p $(TARGET_DIR)
	@echo 'mode: set' > ${COVERAGE_REPORT}
	@rm -f target/unit-tests.log || true
	@for PKG in $(PACKAGES) ; do \
    go test -v $$PKG -coverprofile=${COVERAGE_REPORT}.tmp 2>&1 | tee target/unit-tests.log.tmp ; \
		cat ${COVERAGE_REPORT}.tmp | tail +2 >> ${COVERAGE_REPORT} ; \
		rm -f ${COVERAGE_REPORT}.tmp ; \
		cat target/unit-tests.log.tmp >> target/unit-tests.log ; \
		rm -f target/unit-tests.log.tmp ; \
	done
	@cat target/unit-tests.log | go-junit-report > $@
	@if grep '^FAIL' target/unit-tests.log; then \
		exit 1; \
	fi

${GOPATH}/bin/go-junit-report:
	@go get -u github.com/jstemmer/go-junit-report
