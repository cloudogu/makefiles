# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)

# Set these to the desired values
ARTIFACT_ID=
VERSION=
BUILD_TIME:=$(shell date +%FT%T%z)
COMMIT_ID:=$(shell git rev-parse HEAD)
WORKDIR=$(shell pwd)
MAKEFILES_VERSION=0.0.1b

# choose the environment, if BUILD_URL environment variable is available then we are on ci (jenkins)
ifdef BUILD_URL
ENVIRONMENT=ci
else
ENVIRONMENT=local
endif

# default goal is "compile"
#
.DEFAULT_GOAL:=compile

# updating dependencies
include build/make/dependencies_glide.mk

# Build step
nclude build/make/build.mk

# unit tests
include build/make/unit-test.mk

# static analysis
include build/make/static-analysis.mk

# clean lifecycle
include build/make/clean.mk

.PHONY: update-makefiles
update-makefiles:
	@echo Updating makefiles...
	curl -L --silent https://github.com/cloudogu/makefiles/archive/v$(MAKEFILES_VERSION).tar.gz > ./build/tmp/makefiles-v$(MAKEFILES_VERSION).tar.gz

	tar -xzf ./build/tmp/makefiles-v$(MAKEFILES_VERSION).tar.gz -C ./build/tmp
	cp -r ./build/tmp/makefiles-$(MAKEFILES_VERSION)/build/make ./build/
