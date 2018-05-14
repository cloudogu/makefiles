COMMIT_ID=git rev-parse HEAD
BRANCH=git branch | grep \* | sed 's/ /\n/g' | head -2 | tail -1

.PHONY: info
info:
	@echo "dumping build information ..."
	@echo "Version    : $(VERSION)"
	@echo "Snapshot   : $(SNAPSHOT)"
	@echo "Commit-ID  : $(COMMIT_ID)"
	@echo "Environment: $(ENVIRONMENT)"
	@echo "Branch     : $(BRANCH)"
	@echo "Packages   : $(PACKAGES)"