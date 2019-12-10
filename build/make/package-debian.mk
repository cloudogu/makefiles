PREPARE_PACKAGE?=prepare-package
DEBIAN_PACKAGE_FORMAT_VERSION="2.0"
CONFFILES_FILE="$(DEBIAN_CONTENT_DIR)/control/conffiles"
CONFFILES_FILE_TMP="$(DEBIAN_CONTENT_DIR)/conffiles_"
DEBSRC:=$(shell find "${WORKDIR}/deb" -type f)

.PHONY: package
package: debian-with-binary

.PHONY: debian
debian: $(DEBIAN_PACKAGE)

.PHONY: debian-with-binary
debian-with-binary: $(BINARY) $(DEBIAN_PACKAGE)

.PHONY: prepare-package
prepare-package:
	@echo "Using default prepare-package target. To write your own, define a target and specify it in the PREPARE_PACKAGE variable, before the package-debian.mk import"

$(DEBIAN_BUILD_DIR):
	@mkdir $@

$(DEBIAN_BUILD_DIR)/debian-binary: $(DEBIAN_BUILD_DIR)
	@echo $(DEBIAN_PACKAGE_FORMAT_VERSION) > $@

$(DEBIAN_CONTENT_DIR)/control:
	@install -p -m 0755 -d $@

$(DEBIAN_CONTENT_DIR)/data:
	@install -p -m 0755 -d $@

$(DEBIAN_PACKAGE): $(TARGET_DIR) $(DEBIAN_CONTENT_DIR)/control $(DEBIAN_CONTENT_DIR)/data $(DEBIAN_BUILD_DIR)/debian-binary $(PREPARE_PACKAGE) $(DEBSRC)
	@echo "Creating .deb package..."

# populate control directory
	@sed -e "s/^Version:.*/Version: $(VERSION)/g" deb/DEBIAN/control > $(DEBIAN_CONTENT_DIR)/_control
	@install -p -m 0644 $(DEBIAN_CONTENT_DIR)/_control $(DEBIAN_CONTENT_DIR)/control/control

# populate data directory
	@for dir in $$(find deb -mindepth 1 -not -name "DEBIAN" -a -type d |sed s@"^deb/"@"$(DEBIAN_CONTENT_DIR)/data/"@) ; do \
		install -m 0755 -d $${dir} ; \
	done

	@for file in $$(find deb -mindepth 1 -type f | grep -v "DEBIAN") ; do \
		cp $${file} $(DEBIAN_CONTENT_DIR)/data/$${file#deb/} ; \
	done

# Copy binary to data/usr/sbin, if it exists
	@if [ -f $(BINARY) ]; then \
		echo "Copying binary to $(DEBIAN_CONTENT_DIR)/data/usr/sbin"; \
		install -p -m 0755 -d $(DEBIAN_CONTENT_DIR)/data/usr/sbin; \
		install -p -m 0755 $(BINARY) $(DEBIAN_CONTENT_DIR)/data/usr/sbin/; \
	fi

# create conffiles file which help to deal with config change
# in order to successfully add the conffiles file to the archive it must exist, even empty
	@touch $(CONFFILES_FILE_TMP)
	@for file in $$(find $(DEBIAN_CONTENT_DIR)/data/etc -mindepth 1 -type f | grep -v "DEBIAN") ; do \
		echo $$file | sed s@'.*\(/etc/\)@\1'@ >> $(CONFFILES_FILE_TMP) ; \
	done
	@install -p -m 0644 $(CONFFILES_FILE_TMP) $(CONFFILES_FILE)
	@rm $(CONFFILES_FILE_TMP)

# create control.tar.gz
	@tar cvfz $(DEBIAN_CONTENT_DIR)/control.tar.gz -C $(DEBIAN_CONTENT_DIR)/control $(TAR_ARGS) .

# create data.tar.gz
	@tar cvfz $(DEBIAN_CONTENT_DIR)/data.tar.gz -C $(DEBIAN_CONTENT_DIR)/data $(TAR_ARGS) .

# create package
	@ar roc $@ $(DEBIAN_BUILD_DIR)/debian-binary $(DEBIAN_CONTENT_DIR)/control.tar.gz $(DEBIAN_CONTENT_DIR)/data.tar.gz
	@echo "... deb package can be found at $@"

APTLY:=curl --silent --show-error --fail -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}"

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
