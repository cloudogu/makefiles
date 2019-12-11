# Set these to the desired values
ARTIFACT_ID=
VERSION=

MAKEFILES_VERSION=1.0.6

.DEFAULT_GOAL:=compile

# set PRE_COMPILE to define steps that shall be executed before the go build
# PRE_COMPILE=

# set PRE_UNITTESTS and POST_UNITTESTS to define steps that shall be executed before or after the unit tests
# PRE_UNITTESTS?=
# POST_UNITTESTS?=

# set PREPARE_PACKAGE to define a target that should be executed before the package build
# PREPARE_PACKAGE=

# set ADDITIONAL_CLEAN to define a target that should be executed before the clean target, e.g.
# ADDITIONAL_CLEAN=clean_deb
# clean_deb:
#     rm -rf ${DEBIAN_BUILD_DIR}

include build/make/variables.mk

# You may want to overwrite existing variables for target actions to fit into your project.

include build/make/self-update.mk
include build/make/info.mk
# either dependencies-glide.mk
include build/make/dependencies-glide.mk
# or dependencies-godep.mk
include build/make/dependencies-godep.mk
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
include build/make/digital-signature.mk
include build/make/yarn.mk
include build/make/bower.mk

