.PHONY: prepare-package
prepare-package:
	@echo "Default prepare-package, to write your own, simply define a prepare-package goal in the base Makefile (AFTER importing package-tar.mk)"

.PHONY: package
package: targz-package

targz-package: $(TARGET_DIR)/$(ARTIFACT_ID) prepare-package
	# Check owner and group id
	@cd $(TARGET_DIR) && tar cvf $(ARTIFACT_ID)-$(VERSION).tar $(ARTIFACT_ID) --owner=cloudogu:1000 --group=cloudogu:1000 --mtime="$(LAST_COMMIT_DATE)" --sort=name && gzip -fcn $(ARTIFACT_ID)-$(VERSION).tar >$(ARTIFACT_ID)-$(VERSION).tar.gz

