.PHONY: digital_signature

digital_signature: preparartion creating_checksum generating_signature

preparartion:
	@rm -f $(TARGET_DIR)/Checksums.asc $(TARGET_DIR)/Checksums.sha256sum

creating_checksum:
	@echo "Generating Checksums"
	@$(foreach file,$(wildcard $(TARGET_DIR)/*), shasum -a 256 $(file) >> $(TARGET_DIR)/Checksums.sha256sum;)

generating_signature:
	@echo "Generating Signature"
	@gpg --detach-sign -o $(TARGET_DIR)/Checksums.asc $(TARGET_DIR)/Checksums.sha256sum

