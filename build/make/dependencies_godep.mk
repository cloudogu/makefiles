GODEP=$(GOPATH)/bin/dep

$(GODEP):
	go get -u github.com/golang/dep/cmd/dep

dependencies: $(GODEP)
	dep ensure