# This makefile holds the dogu-release target for starting a new dogu release

.PHONY: dogu-release
dogu-release:
	build/make/dogu_release.sh

.PHONY: go-release
go-release:
	build/make/go_release.sh