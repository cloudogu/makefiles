# This Makefile holds all targets for deploying and undeploying

# Attention: This Makefile depends on package-debian.mk!

.PHONY: deploy-check
deploy-check:
	@case X"${VERSION}" in *-SNAPSHOT) echo "i will not upload a snaphot version for you" ; exit 1; esac;
	@if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
	@if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
	@if [ X"${APT_API_SIGNPHRASE}" = X"" ] ; then echo "supply an APT_API_SIGNPHRASE environment variable"; exit 1; fi;

.PHONY: upload-package
upload-package: deploy-check $(DEBIAN_PACKAGE)
	@echo "... uploading package"
	@$(APTLY) -F file=@"${DEBIAN_PACKAGE}" "${APT_API_BASE_URL}/files/$$(basename ${DEBIAN_PACKAGE})"

.PHONY: add-package-to-repo
add-package-to-repo: upload-package
	@echo "... add package to repositories"
	# heads up: For migration to a new repo structure we use two repos, new (ces) and old (xenial)
	# '?noRemove=1': aptly removes the file on success. This leads to an error on the second package add. Keep it this round
	@$(APTLY) -X POST "${APT_API_BASE_URL}/repos/ces/file/$$(basename ${DEBIAN_PACKAGE})?noRemove=1"
	@$(APTLY) -X POST "${APT_API_BASE_URL}/repos/xenial/file/$$(basename ${DEBIAN_PACKAGE})"

define aptly_publish
	$(APTLY) -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/$(1)/$(2)
endef

.PHONY: publish
publish:
	@echo "... publish packages"
	@$(call aptly_publish,xenial,xenial)
	@$(call aptly_publish,ces,xenial)
	@$(call aptly_publish,ces,bionic)

.PHONY: deploy
deploy: add-package-to-repo publish

define aptly_undeploy
	PREF=$$(${APTLY} "${APT_API_BASE_URL}/repos/$(1)/packages?q=${ARTIFACT_ID}%20(${VERSION})"); \
	${APTLY} -X DELETE -H 'Content-Type: application/json' --data "{\"PackageRefs\": $${PREF}}" ${APT_API_BASE_URL}/repos/$(1)/packages
endef

.PHONY: remove-package-from-repo
remove-package-from-repo:
	@$(call aptly_undeploy,xenial)
	@$(call aptly_undeploy,ces)

.PHONY: undeploy
undeploy: deploy-check remove-package-from-repo publish

.PHONE: lint-deb-package
lint-deb-package: debian
	@lintian -i $(DEBIAN_PACKAGE)
