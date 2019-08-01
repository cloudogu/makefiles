TARGET_DIR=target

WORKDIR:=$(shell pwd)
BUILD_DIR=$(WORKDIR)/build
TMP_DIR:=$(BUILD_DIR)/tmp

BINARY:=$(TARGET_DIR)/$(ARTIFACT_ID)

COMMIT_ID:=$(shell git rev-parse HEAD)
LAST_COMMIT_DATE=$(shell git rev-list --format=format:'%ci' --max-count=1 `git rev-parse HEAD` | tail -1)
BRANCH=$(shell git branch | grep \* | sed 's/ /\n/g' | head -2 | tail -1)

# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)


SRC:=$(shell find "${WORKDIR}" -type f -name "*.go" -not -path "./vendor/*")
DEBSRC:=$(shell find "${WORKDIR}/deb" -type f)

# debian stuff
DEBIAN_BUILD_DIR=$(BUILD_DIR)/deb
DEBIAN_CONTENT_DIR=$(DEBIAN_BUILD_DIR)/content
DEBIAN_PACKAGE=$(TARGET_DIR)/$(ARTIFACT_ID)_$(VERSION).deb
APT_API_BASE_URL=https://apt-api.cloudogu.com/api

# choose the environment, if BUILD_URL environment variable is available then we are on ci (jenkins)
ifdef BUILD_URL
ENVIRONMENT=ci
else
ENVIRONMENT=local
endif


UID_NR:=$(shell id -u)
GID_NR:=$(shell id -g)
HOME_DIR=$(TMP_DIR)/home
PASSWD=$(TMP_DIR)/passwd

$(TMP_DIR):
	@mkdir -p $(TMP_DIR)

$(HOME_DIR): $(TMP_DIR)
	@mkdir -p $(HOME_DIR)

$(PASSWD): $(TMP_DIR)
	@echo "$(USER):x:$(UID_NR):$(GID_NR):$(USER):/home/$(USER):/bin/bash" > $(PASSWD)
