# Set these to the desired values
ARTIFACT_ID=makefiles
MAKEFILES_VERSION=10.0.0
VERSION=${MAKEFILES_VERSION}

.DEFAULT_GOAL:=help

include build/make/variables.mk
include build/make/clean.mk
include build/make/digital-signature.mk
include build/make/release.mk
include build/make/bats.mk

##@ Makefiles Release
.PHONY: makefiles-release
makefiles-release: ## Start a Makefiles release
	build/make/release.sh makefiles
