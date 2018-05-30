CHECKSUMS=checksums
CHECKSUM_FILE=$(TARGET_DIR)/$(CHECKSUMS).sha256sum
SIGNATURE_FILE=$(TARGET_DIR)/$(CHECKSUMS).asc

.PHONY: signature

signature: preparartion creating_checksum generating_signature

preparartion:
	@rm -f $(SIGNATURE_FILE) $(CHECKSUM_FILE)

creating_checksum:
	@echo "Generating Checksums"
	@shasum -a 256 $(TARGET_DIR)/* >> $(CHECKSUM_FILE)

generating_signature:
	@echo "Generating Signature"
	@gpg --detach-sign -o $(SIGNATURE_FILE) $(CHECKSUM_FILE)

