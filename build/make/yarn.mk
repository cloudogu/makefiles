YARN_TARGET=$(WORKDIR)/node_modules
YARN_LOCK=$(WORKDIR)/yarn.lock

.PHONY: yarn-install
yarn-install: $(YARN_TARGET)

$(YARN_TARGET): $(YARN_LOCK) $(PASSWD) $(WORKDIR)
	@echo "Executing yarn..."
	@docker run --rm \
	  -u "$(UID_NR):$(GID_NR)" \
	  -v $(PASSWD):/etc/passwd:ro \
	  -v $(WORKDIR):$(WORKDIR) \
	  -w $(WORKDIR) \
	  node:8 \
	  yarn install
