# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

Please note: Breaking change ahead. 

### Added

- Support of proper integration tests

By default all go packages in the project are subject to the `integration-test` target. To reduce the foot print and test run time the variable containing the selected packages can be overwritten in the main Makefile like this (after including the `variables.mk` files but before the integration test inclusion.

This example extracts only the package paths for the packages `tasks` and `registry`:

```makefile
PACKAGES_FOR_INTEGRATION_TEST=$(shell go list ./... | grep 'tasks\|registry')
```

### Changed

- Moved `update-makefiles` target to its own file

Previously the main Makefile was the place to accommodate the update-makefiles target.
Since it is encouraged (even more: necessary) to edit the main Makefile in order to customize a project's build process this file is never going to be updated. In order to allow the migration process of updating this routine moves to the `self-update.mk` file.

After updating to this version you SHOULD remove the `update-makefiles` from the main Makefile in order to avoid make target conflicts.

Also, if the update-makefiles target is called, all filial makefiles under `build/make/` are deleted.

- Changed files

Please include these files for your tests. It is possible to include neither, only one, or both files for unit and integration tests. Both need `test-common.mk` included beforehand.

- `test-common.mk`
- `test-unit.mk`
- `test-integration`

### Removed

The test-related filial makefiles are *deleted* in favour of new makefiles which orient better in the file system:

- `integration-test.mk`
- `unit-test-docker-compose.mk`

Please include instead these files:

- `test-common.mk`
- `test-unit.mk`
- `test-integration`

Please note that `test-common.mk` must be included before the other two.