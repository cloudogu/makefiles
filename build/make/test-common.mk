$(GOPATH)/bin/go-junit-report:
	@GO111MODULE=off $(GO_CALL) get -u github.com/jstemmer/go-junit-report
