GLIDE=$(GOPATH)/bin/glide
GLIDEFLAGS=

ifeq ($(ENVIRONMENT), ci)
	GLIDEFLAGS+=--no-color
endif

.PHONY: update-dependencies
update-dependencies: glide.lock

.PHONY: dependencies
dependencies: $(GLIDE)
	@echo "installing dependencies ..."
	$(GLIDE) $(GLIDEFLAGS) install -v

$(GLIDE): 
	curl https://glide.sh/get | sh

glide.lock: glide.yaml $(GLIDE)
	$(GLIDE) $(GLIDEFLAGS) up -v
