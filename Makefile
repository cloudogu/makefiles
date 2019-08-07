# Set these to the desired values
ARTIFACT_ID=
VERSION=

MAKEFILES_VERSION= # Set this once we have a stable release

.DEFAULT_GOAL:=compile

# set PRE_COMPILE to define steps that shall be executed before the go build
# PRE_COMPILE=

include build/make/variables.mk

include build/make/info.mk

include build/make/dependencies-glide.mk

include build/make/build.mk

include build/make/unit-test.mk

include build/make/static-analysis.mk

include build/make/clean.mk

include build/make/package-debian.mk

include build/make/digital-signature.mk

include build/make/yarn.mk

include build/make/bower.mk




.PHONY: update-makefiles
update-makefiles:
	@echo Updating makefiles...
	@curl -L --silent https://github.com/cloudogu/makefiles/archive/v$(MAKEFILES_VERSION).tar.gz > $(TMP_DIR)/makefiles-v$(MAKEFILES_VERSION).tar.gz

	@tar -xzf $(TMP_DIR)/makefiles-v$(MAKEFILES_VERSION).tar.gz -C $(TMP_DIR)
	@cp -r $(TMP_DIR)/makefiles-$(MAKEFILES_VERSION)/build/make $(BUILD_DIR)
