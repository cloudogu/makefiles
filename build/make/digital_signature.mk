CHECKSUMS=checksums
CHECKSUM_FILE=$(TARGET_DIR)/$(CHECKSUMS).sha256sum
SIGNATURE_FILE=$(TARGET_DIR)/$(CHECKSUMS).asc

.PHONY: signature

signature: preparartion creating_checksum generating_signature

preparartion:
	@rm -f $(SIGNATURE_FILE) $(CHECKSUM_FILE)

creating_checksum:
	@echo "Generating Checksums"
	@$(foreach file,$(wildcard $(TARGET_DIR)/*), shasum -a 256 $(file) >> $(CHECKSUM_FILE);)

generating_signature:
	@echo "Generating Signature"
ifneq (,$(wildcard $(CHECKSUM_FILE)))
	@gpg --detach-sign -o $(SIGNATURE_FILE) $(CHECKSUM_FILE)
else
	@echo "cannot generate signature since no checksum file exists"
endif

