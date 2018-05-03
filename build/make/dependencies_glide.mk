.PHONY: update-dependencies
update-dependencies: glide.lock

glide.lock: glide.yaml
	${GLIDE} ${GLIDEFLAGS} up -v
