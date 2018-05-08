XUNIT_XML=target/unit-tests.xml

unit-test: ${XUNIT_XML}

${XUNIT_XML}:
	mkdir -p $(TARGET_DIR)
	if [ X"${ENVIRONMENT}" = X"local" ] ; then \
		docker-compose up -d; \
	fi;
	go test -v $(PACKAGES) | tee target/unit-tests.log
	@if grep '^FAIL' target/unit-tests.log; then \
		exit 1; \
	fi
	cat target/unit-tests.log | go2xunit -output $@
	if [ X"${ENVIRONMENT}" = X"local" ] ; then \
		docker-compose kill; \
	fi;
