clean:
	rm -rf ${TARGET_DIR}

dist-clean: clean
	rm -rf node_modules
	rm -rf public/vendor
	rm -rf vendor
	rm -rf npm-cache
	rm -rf bower
