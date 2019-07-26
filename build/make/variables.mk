TARGET_DIR=target

COMMIT_ID:=$(shell git rev-parse HEAD)
LAST_COMMIT_DATE=$(shell git rev-list --format=format:'%ci' --max-count=1 `git rev-parse HEAD` | tail -1)
BRANCH=$(shell git branch | grep \* | sed 's/ /\n/g' | head -2 | tail -1)

# collect packages and dependencies for later usage
PACKAGES=$(shell go list ./... | grep -v /vendor/)

WORKDIR=$(shell pwd)

# choose the environment, if BUILD_URL environment variable is available then we are on ci (jenkins)
ifdef BUILD_URL
ENVIRONMENT=ci
else
ENVIRONMENT=local
endif
