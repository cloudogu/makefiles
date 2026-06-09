# Set these to the desired values
ARTIFACT_ID=makefiles
VERSION=10.9.1
MAKEFILES_VERSION=${VERSION}

.DEFAULT_GOAL:=help

include build/make/variables.mk
include build/make/clean.mk
include build/make/digital-signature.mk
include build/make/release.mk
include build/make/bats.mk
include build/make/k8s.mk ## Include for testing purpose

##@ Makefiles Release
.PHONY: makefiles-release
makefiles-release: ## Start a Makefiles release
	build/make/release.sh makefiles
