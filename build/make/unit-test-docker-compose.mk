PRE_UNITTESTS?=start-docker-compose
.PHONY: start-docker-compose
start-docker-compose:
	@if [ X"${ENVIRONMENT}" = X"local" ] ; then \
		docker-compose up -d; \
	fi;

POST_UNITTESTS?=stop-docker-compose
.PHONY: stop-docker-compose
stop-docker-compose:
	@if [ X"${ENVIRONMENT}" = X"local" ] ; then \
		docker-compose kill; \
	fi;

include build/make/unit-test.mk
