GODEP=$(GOPATH)/bin/dep

$(GODEP):
	go get -u github.com/golang/dep/cmd/dep

update-dependencies: $(GODEP)
	dep ensure