# used to create switch the dogu to a prerelease namespace
# e.g. official/usermgmt -> prerelease/official_usermgmt

.PHONY: prerelease_namespace
prerelease_namespace:
	build/make/stagex.sh prerelease_namespace