# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)

# Set these to the desired values
ARTIFACT_ID=
VERSION=
BUILD_TIME:=$(shell date +%FT%T%z)
COMMIT_ID:=$(shell git rev-parse HEAD)
WORKDIR=$(shell pwd)
TARGET_DIR=target

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
include build/make/build.mk

# unit tests
include build/make/unit-test.mk

# static analysis
include build/make/static-analysis.mk

# clean lifecycle
include build/make/clean.mk

include build/make/update-makefiles.mk

include build/make/package-debian.mk
