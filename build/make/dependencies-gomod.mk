.PHONY: dependencies
dependencies: vendor

vendor:
	@echo "Installing dependencies using go modules..."
	${GO_CALL} mod vendor
