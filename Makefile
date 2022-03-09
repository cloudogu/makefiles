# Set these to the desired values
ARTIFACT_ID=
VERSION=

MAKEFILES_VERSION=5.0.0

.DEFAULT_GOAL:=help

# set PRE_COMPILE to define steps that shall be executed before the go build
# PRE_COMPILE=

# set GO_ENV_VARS to define go environment variables for the go build
# GO_ENV_VARS = CGO_ENABLED=0

# set PRE_UNITTESTS and POST_UNITTESTS to define steps that shall be executed before or after the unit tests
# PRE_UNITTESTS?=
# POST_UNITTESTS?=

# set PREPARE_PACKAGE to define a target that should be executed before the package build
# PREPARE_PACKAGE=

# set ADDITIONAL_CLEAN to define a target that should be executed before the clean target, e.g.
# ADDITIONAL_CLEAN=clean_deb
# clean_deb:
#     rm -rf ${DEBIAN_BUILD_DIR}

# APT_REPO controls the target apt repository for deploy-debian.mk
# -> APT_REPO=ces-premium results in a deploy to the premium apt repository
# -> Everything else results in a deploy to the public repositories
APT_REPO?=ces

include build/make/variables.mk

# You may want to overwrite existing variables for target actions to fit into your project.

include build/make/self-update.mk
include build/make/dependencies-gomod.mk
include build/make/build.mk
include build/make/test-common.mk
include build/make/test-integration.mk
include build/make/test-unit.mk
include build/make/static-analysis.mk
include build/make/clean.mk
# either package-tar.mk
include build/make/package-tar.mk
# or package-debian.mk
include build/make/package-debian.mk
# deploy-debian.mk depends on package-debian.mk
include build/make/deploy-debian.mk
include build/make/digital-signature.mk
include build/make/yarn.mk
include build/make/bower.mk
# only include this in dogu repositories
include build/make/release.mk

