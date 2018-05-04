DEBIAN_TARGET_DIR=$(TARGET_DIR)/deb/content
DEBIAN_PACKAGE=$(TARGET_DIR)/deb/$(ARTIFACT_ID)_$(VERSION).deb


$(TARGET_DIR)/debian-binary:
	echo "2.0" > $@

$(DEBIAN_PACKAGE): compile $(TARGET_DIR)/debian-binary
	@echo "Creating Ubuntu 16.04 (Deb Xerus) package..."

	install -m 0755 -d $(DEBIAN_TARGET_DIR)/control
	sed -e "s/^Version:.*/Version: $(VERSION)/g" deb/DEBIAN/control > $(DEBIAN_TARGET_DIR)/_control
	install -m 0644 $(DEBIAN_TARGET_DIR)/_control $(DEBIAN_TARGET_DIR)/control/control

# creating control.tar.gz
	tar cvzf $(DEBIAN_TARGET_DIR)/control.tar.gz -C $(DEBIAN_TARGET_DIR)/control  --owner=0 --group=0 .
# populating data directory
	install -m 0755 -d $(DEBIAN_TARGET_DIR)/data/usr/sbin
	install -m 0755 -d $(DEBIAN_TARGET_DIR)/data/etc/bash_completion.d/

	for dir in $$(find deb -mindepth 1 -not -name "DEBIAN" -a -type d |sed s@"^deb/"@"$(DEBIAN_TARGET_DIR)/data/"@) ; do install -m 0755 -d $${dir} ; done
	for file in $$(find deb -mindepth 1 -type f | grep -v "DEBIAN") ; do install -m 0644 $${file} $(DEBIAN_TARGET_DIR)/data/$${file#deb/}; done
	install -m 0755 $(ARTIFACT_ID) $(DEBIAN_TARGET_DIR)/data/usr/sbin/
	cp $(GOPATH)/src/github.com/cloudogu/cesapp/vendor/github.com/codegangsta/cli/autocomplete/bash_autocomplete $(DEBIAN_TARGET_DIR)/data/etc/bash_completion.d/cesapp

# creating data.tar.gz
	tar cvzf $(DEBIAN_TARGET_DIR)/data.tar.gz -C $(DEBIAN_TARGET_DIR)/data --owner=0 --group=0 .
# creating package
	ar rc $@ $(TARGET_DIR)/debian-binary $(DEBIAN_TARGET_DIR)/control.tar.gz $(DEBIAN_TARGET_DIR)/data.tar.gz
	@echo "... deb package can be found at $@"
