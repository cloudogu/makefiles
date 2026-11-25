##@ Renovate

# Files that contain <PREFIX>_URL/<PREFIX>_CHECKSUM pairs, see docs/development/renovate-checksums.md
CHECKSUM_FILES?=Dockerfile

.PHONY: update-checksums
update-checksums: ## Update the sha256 checksums of downloads whose resolved URL changed since the last commit
	@build/make/renovate.sh update-checksums $(CHECKSUM_FILES)
