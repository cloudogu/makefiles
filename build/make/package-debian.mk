PREPARE_PACKAGE?=prepare-package

.PHONY: package
package: $(DEBIAN_PACKAGE)

.PHONY: debian
debian: $(DEBIAN_PACKAGE)

.PHONY: prepare-package
prepare-package:
	@echo "Default prepare-package, to write your own, define a your own target and specify it in the PREPARE_PACKAGE variable, before the package-debian.mk import"

$(DEBIAN_BUILD_DIR):
	@mkdir $@

$(DEBIAN_BUILD_DIR)/debian-binary: $(DEBIAN_BUILD_DIR)
	@echo "2.0" > $@

$(DEBIAN_PACKAGE): $(BINARY) $(DEBIAN_BUILD_DIR)/debian-binary ${PREPARE_PACKAGE} $(DEBSRC)
	@echo "Creating .deb package..."

	@install -p -m 0755 -d $(DEBIAN_CONTENT_DIR)/control
	@sed -e "s/^Version:.*/Version: $(VERSION)/g" deb/DEBIAN/control > $(DEBIAN_CONTENT_DIR)/_control
	@install -p -m 0644 $(DEBIAN_CONTENT_DIR)/_control $(DEBIAN_CONTENT_DIR)/control/control

# creating control.tar.gz
	@tar cvf $(DEBIAN_CONTENT_DIR)/control.tar -C $(DEBIAN_CONTENT_DIR)/control --owner=cloudogu:1000 --group=cloudogu:1000 --mtime="$(LAST_COMMIT_DATE)" --sort=name .
	@gzip -fcn $(DEBIAN_CONTENT_DIR)/control.tar > $(DEBIAN_CONTENT_DIR)/control.tar.gz

# populating data directory
	@for dir in $$(find deb -mindepth 1 -not -name "DEBIAN" -a -type d |sed s@"^deb/"@"$(DEBIAN_CONTENT_DIR)/data/"@) ; do install -m 0755 -d $${dir} ; done
	@for file in $$(find deb -mindepth 1 -type f | grep -v "DEBIAN") ; do install -m 0644 $${file} $(DEBIAN_CONTENT_DIR)/data/$${file#deb/}; done

# Copy binary to /usr/sbin, if it exists
	@if [ -f $(BINARY) ]; then \
		echo "Copying binary to /usr/sbin"; \
		install -p -m 0755 -d $(DEBIAN_CONTENT_DIR)/data/usr/sbin; \
		install -p -m 0755 $(BINARY) $(DEBIAN_CONTENT_DIR)/data/usr/sbin/; \
	fi

# creating data.tar.gz
	@tar cvf $(DEBIAN_CONTENT_DIR)/data.tar -C $(DEBIAN_CONTENT_DIR)/data --owner=cloudogu:1000 --group=cloudogu:1000 --mtime="$(LAST_COMMIT_DATE)" --sort=name .
	@gzip -fcn $(DEBIAN_CONTENT_DIR)/data.tar > $(DEBIAN_CONTENT_DIR)/data.tar.gz
# creating package
	@ar roc $@ $(DEBIAN_BUILD_DIR)/debian-binary $(DEBIAN_CONTENT_DIR)/control.tar.gz $(DEBIAN_CONTENT_DIR)/data.tar.gz
	@echo "... deb package can be found at $@"

# deployment
.PHONY: deploy-check
deploy-check:
	@case X"${VERSION}" in *-SNAPSHOT) echo "i will not upload a snaphot version for you" ; exit 1; esac;
	@if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
	@if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
	@if [ X"${APT_API_SIGNPHRASE}" = X"" ] ; then echo "supply an APT_API_SIGNPHRASE environment variable"; exit 1; fi;

.PHONY: upload-package
upload-package: deploy-check $(DEBIAN_PACKAGE)
	@echo "... uploading package"
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -F file=@"${DEBIAN_PACKAGE}" "${APT_API_BASE_URL}/files/${DEBIAN_PACKAGE}"

.PHONY: add-package-to-repo
add-package-to-repo: upload-package
	@echo "... add package to repositories"
	# @curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X POST "${APT_API_BASE_URL}/repos/xenial/file/${DEBIAN_PACKAGE}"
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X POST "${APT_API_BASE_URL}/repos/ces/file/${DEBIAN_PACKAGE}"

define aptly_publish
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/$(1)/$(2)
endef

.PHONY: publish
publish: add-package-to-repo
	@echo "... publish packages"
	# @curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial
	# @curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/ces/xenial
	# @curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/ces/bionic
	$(aptly_publish "ces", "xenial")
	$(aptly_publish "ces", "bionic")

.PHONY: deploy
deploy: publish

.PHONY: undeploy
undeploy: deploy-check
	PREF=$$(curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/ces/packages?q=${ARTIFACT_ID}%20(${VERSION})"); \
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X DELETE -H 'Content-Type: application/json' --data "{\"PackageRefs\": $${PREF}}" ${APT_API_BASE_URL}/repos/ces/packages
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/ces
  #PREF=$$(curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/xenial/packages?q=${ARTIFACT_ID}%20(${VERSION})"); \
	#curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X DELETE -H 'Content-Type: application/json' --data "{\"PackageRefs\": $${PREF}}" ${APT_API_BASE_URL}/repos/xenial/packages
	#curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial


upload-info: deploy-check
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/files" |jq
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/files/xenial" |jq

repo-info: deploy-check
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos" |jq
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/xenial" |jq
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/xenial/packages" |jq

pub-info: deploy-check
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/publish" |jq

create-repos: deploy-check
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X POST -H 'Content-Type: application/json' --data '{"Name": "xenial", "DefaultDistribution": "xenial", "DefaultComponent": "main"}' "${APT_API_BASE_URL}/repos" |jq
