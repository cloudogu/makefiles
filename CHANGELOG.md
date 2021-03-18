# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Debian package (un)deployment for focal (Ubuntu 20.04); #56

### Removed
- Debian package (un)deployment for xenial (Ubuntu 16.04); #56

## [v4.3.1](https://github.com/cloudogu/makefiles/releases/tag/v4.3.1) 2021-1-25
### Changed
- Calls an additional `go mod vendor` after installing `j-unit-report` to prevent inconsistencies between `go.mod` and `vendor/modules.txt` [#53]. 

## [v4.3.0](https://github.com/cloudogu/makefiles/releases/tag/v4.3.0) 2020-12-17

**Breaking Change ahead!**, see below

### Changed
- Replace custom `cloudogu/golang` container with official golang container (#51)
   - The affected targets are:
      - `build`
      - `static-analysis-ci`
      - `static-analysis-local`
   - The targets `static-analysis`/`static-analysis-ci` may no longer work on your CI because of changed container references
      - mounting a custom `/etc/passwd` into the golang container is advised
   - Golang containers default to version 1.14.13 now
      - the Go compiler version is adjustable via the `GOTAG` variable
      - customized make variables `GOIMAGE` and `GOTAG` should be replaced in your main `Makefile` accordingly
      - see also the [README.md](README.md) for more information

### Added
- Add customizable make variable for Golang container volume mount (#51)
   - f. e.: `CUSTOM_GO_MOUNT=-v /host/path:/container/path`
   - see also the [README.md](README.md) for more information
- Add make variable `ETCGROUP` for generated `/etc/group` file

## [v4.2.0](https://github.com/cloudogu/makefiles/releases/tag/v4.2.0) 2020-05-25
### Fixed
- Set repo-specific user output in deploy-debian.mk

### Added
- dogu-release target to start an automated dogu release

## [v4.1.0](https://github.com/cloudogu/makefiles/releases/tag/v4.1.0)
### Added
- Include a new variable `APT_REPO` which controls which apt repository should be used as a deploy target. `ces-premium` deploys into the premium repository while any other value deploys into the public repositories. ([Issue 45](https://github.com/cloudogu/makefiles/issues/45))
- dogu-release target to start an automated dogu release

## [v4.0.0](https://github.com/cloudogu/makefiles/releases/tag/v4.0.0)

Please note: Default behaviour changed!
The "CGO_ENABLED=0" variable is not set per default any more!
You have to set it via the Makefile, if needed.

### Added
- Introduce GO_ENV_VARS for go environment variables

## [v3.0.1](https://github.com/cloudogu/makefiles/releases/tag/v3.0.1)
### Fixed
- Issue [34](https://github.com/cloudogu/makefiles/issues/34)
  `make unit-test` and `make integration-test` depend on the go sources
  and won't download go-junit-report each time they run

## [v3.0.0](https://github.com/cloudogu/makefiles/releases/tag/v3.0.0)

Please note: Breaking change ahead.

### Added
- Update vendor target to check for new gomod dependencies

### Changed
- Separate the debian package building and deploying targets
   - `package-debian.mk` only holds deb package building targets now
   - `deploy-debian.mk` holds the deb package deployment targets now

When you are upgrading to this version and want to deploy deb packages, you have to
include the `deploy-debian.mk` into your Makefile, below the `package-debian.mk`.
For example, see the [Makefile in this repository](https://github.com/cloudogu/makefiles/blob/develop/Makefile).

## [v2.1.1](https://github.com/cloudogu/makefiles/releases/tag/v2.1.1)
### Changed
- Changed reviewdog -ci flag to -reporter flag in jenkins build
- static-analysis-ci now also executes the goal to create static-analysis.log

## [v2.1.0](https://github.com/cloudogu/makefiles/releases/tag/v2.1.0)
### Added
- Add Go modules support  (#31)
   - Go module is activated by setting GO_ENVIRONMENT=GO111MODULE=on before including variables.mk
   - When working with go modules `dependencies-gomod.mk` has to be included.

### Fixed
- Furthermore this commit fixes a weird unit-test behaviour when the go-junit tool is older than the tests.

## [v2.0.0](https://github.com/cloudogu/makefiles/releases/tag/v2.0.0)

Please note: Breaking change ahead.

### Added

#### Support of proper integration tests (#28)

By default all go packages in the project are subject to the `integration-test` target. To reduce the foot print and test run time the variable containing the selected packages can be overwritten in the main Makefile like this (after including the `variables.mk` files but before the integration test inclusion.

This example extracts only the package paths for the packages `tasks` and `registry`:

```makefile
PACKAGES_FOR_INTEGRATION_TEST=$(shell go list ./... | grep 'tasks\|registry')
```

#### Provide custom `clean` target (#26)

- Added customizable `clean` target
   - This comes handy if more files and directory should be removed during `clean` than the common stuff
   - Appending one's own clean target is easily done by defining the variable `ADDITIONAL_CLEAN` with a custom target name

### Changed

#### Moved `update-makefiles` target to its own file (#28)

Previously the main Makefile was the place to accommodate the update-makefiles target.
Since it is encouraged (even more: necessary) to edit the main Makefile in order to customize a project's build process this file is never going to be updated. In order to allow the migration process of updating this routine moves to the `self-update.mk` file.

After updating to this version you SHOULD remove the `update-makefiles` from the main Makefile in order to avoid make target conflicts.

Please note, if the `update-makefiles` target is called, all filial makefiles under `build/make/` are deleted. The directory `build/make/` are not supposed to contain manual changes. Instead file a [Feature Request in the makefiles repo](https://github.com/cloudogu/makefiles/issues) and update to the following release version.

#### support integration test target (#28)

- Changes in test makefiles to support proper integration tests

Please include these files for your tests. It is possible to include neither, only one, or both files for unit and integration tests. Both need `test-common.mk` included beforehand.

- `test-common.mk`
   - this should be included first because both depend on it
- `test-unit.mk`
- `test-integration`

### Removed

The test-related filial makefiles `integration-test.mk` and `unit-test-docker-compose.mk` are *deleted* in favour of new makefiles which sort better in a directory listing (#28)

### Fix

- Moved a debian related variable to `package-debian.mk` to remove an error message (#30)
- Removed cleaning the directory under `${DEBIAN_BUILD_DIR}` during `clean`
   - This is a specific clean target which belongs to the project's makefile
   - Appending one's own clean target is easily done by defining the variable `ADDITIONAL_CLEAN` with a custom target name (#25)

## [v1.0.6](https://github.com/cloudogu/makefiles/releases/tag/v1.0.6) - 2019-09-11

### Change

- If building a `.tar` file the permissions are now with owner/group ID 0 (#23)

## [v1.0.5](https://github.com/cloudogu/makefiles/releases/tag/v1.0.5) - 2019-09-11

### Add

- Add a deletion rule if building a `.deb` package temporary in which conffiles are now deleted after the debian package building process (#20)

## [v1.0.4](https://github.com/cloudogu/makefiles/releases/tag/v1.0.4) - 2019-09-11

### Add

- Copy files in `deb/data/` to data folder with the access permissions they already have without using the install command. Also now is ensured that the data folder exists. (#18)
