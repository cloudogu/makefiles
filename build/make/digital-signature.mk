CHECKSUM_FILE=checksums.sha256sum
SIGNATURE_FILE=$(CHECKSUM_FILE).asc

.PHONY: signature

signature: preparation creating_checksum generating_signature

preparation:
	@rm -f $(SIGNATURE_FILE) $(CHECKSUM_FILE)

creating_checksum:
	@echo "Generating Checksums"
	@cd $(TARGET_DIR); shasum -a 256 * >> $(CHECKSUM_FILE)

generating_signature:
	@echo "Generating Signature"
	@cd $(TARGET_DIR); gpg --detach-sign -o $(SIGNATURE_FILE) $(CHECKSUM_FILE)

