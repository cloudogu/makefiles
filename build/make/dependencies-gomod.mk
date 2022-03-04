##@ Go mod

.PHONY: dependencies
dependencies: vendor ## Install dependencies using go mod

vendor: go.mod go.sum
	@echo "Installing dependencies using go modules..."
	${GO_CALL} mod vendor
