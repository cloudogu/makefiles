.PHONY: prepare-package
prepare-package:
	@echo "Default prepare-package, to write your own, simply define a prepare-package goal in the base Makefile (AFTER importing package-tar.mk)"

.PHONY: package
package: targz-package checksum-package

targz-package: $(TARGET_DIR)/$(ARTIFACT_ID) prepare-package
	@cd $(TARGET_DIR) && tar cvf $(ARTIFACT_ID)-$(VERSION).tar $(ARTIFACT_ID) --mtime="$(LAST_COMMIT_DATE)" && gzip -fcn $(ARTIFACT_ID)-$(VERSION).tar >$(ARTIFACT_ID)-$(VERSION).tar.gz

checksum-package: targz-package
	@echo "Calculating checksum of tar.gz package"
	@cd $(TARGET_DIR) ; shasum -a 256 $(ARTIFACT_ID)-$(VERSION).tar.gz > $(ARTIFACT_ID)-$(VERSION).tar.gz.sha256sum
