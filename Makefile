# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)

# Set these to the desired values
ARTIFACT_ID=
VERSION=
BUILD_TIME:=$(shell date +%FT%T%z)
COMMIT_ID:=$(shell git rev-parse HEAD)

# Defaults
include defaults.mk

# updating dependencies
include dependencies_glide.mk

# Build step
include build.mk

# unit tests
include unit-test.mk

# static analysis
include static-analysis.mk

# clean lifecycle
include clean.mk

