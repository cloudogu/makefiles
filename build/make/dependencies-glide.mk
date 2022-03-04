##@ Glide dependency management

GLIDE=$(GOPATH)/bin/glide
GLIDEFLAGS=
GLIDEHOME=$(GLIDE_HOME)

ifeq ($(ENVIRONMENT), ci)
	GLIDEFLAGS+=--no-color
	GLIDEHOME=$(WORKDIR)/.glide_home
	GLIDEFLAGS+= --home $(GLIDEHOME)
endif

.PHONY: update-dependencies
update-dependencies: $(GLIDE) ## Install glide

.PHONY: dependencies
dependencies: vendor ## Install dependencies using glide

vendor: $(GLIDE) glide.yaml glide.lock
	@echo "Installing dependencies using Glide..."
	$(GLIDE) $(GLIDEFLAGS) install -v

$(GLIDE):
	@echo "installing glide"
	@curl https://glide.sh/get | sh

