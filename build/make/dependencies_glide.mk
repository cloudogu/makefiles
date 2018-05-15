GLIDE=$(GOPATH)/bin/glide
GLIDEFLAGS=
GLIDEHOME=$(GLIDE_HOME)

ifeq ($(ENVIRONMENT), ci)
	GLIDEFLAGS+=--no-color
	GLIDEHOME=$(WORKDIR)/.glide_home
	GLIDEFLAGS+= --home $(GLIDEHOME)
endif

.PHONY: update-dependencies
update-dependencies: $(GLIDE) glide.lock

.PHONY: dependencies
dependencies: vendor

vendor: $(GLIDE)
	@echo "Installing dependencies using Glide..."
	$(GLIDE) $(GLIDEFLAGS) install -v

$(GLIDE): 
	@curl https://glide.sh/get | sh

