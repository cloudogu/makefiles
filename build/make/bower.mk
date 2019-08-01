BOWER_TARGET=$(WORKDIR)/public/vendor
BOWER_JSON=$(WORKDIR)/bower.json


.PHONY: bower-install
bower-install: $(BOWER_TARGET)

$(BOWER_TARGET): $(BOWER_JSON) $(HOME_DIR) $(WORKDIR) $(PASSWD) $(YARN_TARGET)
	@echo "Executing bower..."
	docker run --rm \
	  -e HOME=/tmp \
	  -u "$(UID_NR):$(GID_NR)" \
	  -v $(PASSWD):/etc/passwd:ro \
	  -v $(WORKDIR):$(WORKDIR) \
	  -w $(WORKDIR) \
	  node:8 \
	  yarn run bower
