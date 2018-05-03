# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)

# Set these to the desired values
ARTIFACT_ID=cesapp
VERSION=6.6.6
BUILD_TIME:=$(shell date +%FT%T%z)
COMMIT_ID:=$(shell git rev-parse HEAD)
WORKDIR=$(shell pwd)

# choose the environment, if BUILD_URL environment variable is available then we are on ci (jenkins)
ifdef BUILD_URL
ENVIRONMENT=ci
GLIDEFLAGS+=--no-color
else
ENVIRONMENT=local
endif

# default goal is "compile"
#
.DEFAULT_GOAL:=compile

# Defaults
include build/make/defaults.mk

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

