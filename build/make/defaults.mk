# directory settings
TARGET_DIR=target/
COMPILE_TARGET_DIR=target/dist/

# make target files
EXECUTABLE=target/dist/${ARTIFACT_ID}
PACKAGE=target/dist/${ARTIFACT_ID}-v${VERSION}.tar.gz
XUNIT_XML=target/unit-tests.xml

# tools
LINT=gometalinter
GLIDE=glide
GO2XUNIT=go2xunit

# flags
LINTFLAGS=--vendor --exclude="vendor" --exclude="_test.go"
LINTFLAGS+=--disable-all --enable=errcheck --enable=vet --enable=golint
LINTFLAGS+=--deadline=2m
LDFLAGS=-ldflags "-extldflags -static -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME} -X main.CommitID=${COMMIT_ID}"
GLIDEFLAGS=


# choose the environment, if BUILD_URL environment variable is available then we are on ci (jenkins)
ifdef BUILD_URL
ENVIRONMENT=ci
GLIDEFLAGS+=--no-color
else
ENVIRONMENT=local
endif


# default goal is "build"
#
.DEFAULT_GOAL:=build


.PHONY: update-dependencies
.PHONY: build dependencies info
.PHONY: static-analysis static-analysis-ci static-analysis-local
.PHONY: integration-test
.PHONY: unit-test
.PHONY: clean dist-clean
