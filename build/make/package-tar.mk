TAR_PACKAGE:=$(ARTIFACT_ID)-$(VERSION).tar.gz

.PHONY: package
package: $(TAR_PACKAGE)

$(TAR_PACKAGE): $(BINARY)
	# Check owner and group id
	@cd $(TARGET_DIR) && tar cvf $(ARTIFACT_ID)-$(VERSION).tar $$(basename ${BINARY}) --owner=cloudogu:1000 --group=cloudogu:1000 --mtime="$(LAST_COMMIT_DATE)" --sort=name && gzip -fcn $(ARTIFACT_ID)-$(VERSION).tar > $(ARTIFACT_ID)-$(VERSION).tar.gz

