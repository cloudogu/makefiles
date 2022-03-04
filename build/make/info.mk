.PHONY: info
info: ## Print build information
	@echo "dumping build information ..."
	@echo "Version    : $(VERSION)"
	@echo "Commit-ID  : $(COMMIT_ID)"
	@echo "Environment: $(ENVIRONMENT)"
	@echo "Branch     : $(BRANCH)"
	@echo "Packages   : $(PACKAGES)"
