# Set these to the desired values
ARTIFACT_ID=makefiles
MAKEFILES_VERSION=8.3.0
VERSION=${MAKEFILES_VERSION}

.DEFAULT_GOAL:=help

include build/make/variables.mk
include build/make/clean.mk
include build/make/digital-signature.mk
include build/make/release.mk
include build/make/bats.mk
