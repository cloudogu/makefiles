# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v10.5.0] - 2025-12-02
### Added
- Add BaseVersion to be able to create backport releases

## [v10.4.0] - 2025-09-25
- [#240] Upgrade golangci-lint to v2.5.0

## [v10.3.0] - 2025-09-24
### Changed
- [#238] Upgrade golang to v1.25
- [#238] Upgrade Controller-gen to v0.19.0

## [v10.2.1] - 2025-08-20
### Changed
- [#235] Updates BATS version to 1.12

### Fixed
- [#235] Fixes bug in which `make unit-test-shell` doesn't generate a xUnit report file. 

## [v10.2.0] - 2025-07-11
### Changed
- [#233] Allow "component-apply" and "crd-component-apply" in development-stage on remote-environments.
- [#233] In development-stage add a timestamp as buildnumber to helm-chart-version to force helm to use the updated chart.

## [v10.1.1] - 2025-06-05
### Fixed
- component-apply and crd-component-apply cannot be executed when:
    - RUNTIME_ENV == remote and Stage == Production.
    - this is so that there's no accidental push to production harbor.

## [v10.1.0] - 2025-06-05
### Added
- Add automatic release process

## [v10.0.0](https://github.com/cloudogu/makefiles/releases/tag/v10.0.0) 2025-06-04

Breaking change ahead! [#223]

### Changed
- [#223] update golangci to v2.1.6
  - if a config file is used or additional LINTFLAGS are set in your project, please check if it is still compatible
  - please do not configure LINT_VERSION <v2.0.0 as the configuration set by the makefiles will not be compatible
- [#223] remove mock exclusion flags from LINTFLAGS as it is an integrated golangci feature now

## [v9.10.0](https://github.com/cloudogu/makefiles/releases/tag/v9.10.0) 2025-04-25
### Changed
- use json test output only in CI-Mode

## [v9.9.1](https://github.com/cloudogu/makefiles/releases/tag/v9.9.1) 2025-04-09
### Changed
- Fixed sed command in prerelease.sh to only grab version from label

## [v9.9.0](https://github.com/cloudogu/makefiles/releases/tag/v9.9.0) 2025-03-28
### Added
- [#224] `APPEND_CRD_SUFFIX`-flag that decides if `-crd`-Suffix should be appended to the `ARTIFACT_ID`
### Changed
- [#224] `ARTIFACT_CRD_ID` is now equal to `ARTIFACT_ID` if `APPEND_CRD_SUFFIX` is `false`.
- Update go version tag to `1.24`
- Update golangci-lint to `v1.64.8`
- Update mockery to `v2.53.3`

## [v9.8.0](https://github.com/cloudogu/makefiles/releases/tag/v9.8.0) 2025-03-14
### Added
- [#218] Custom Maketarget for scanning dogu-images with trivy

## [v9.7.0](https://github.com/cloudogu/makefiles/releases/tag/v9.7.0) 2025-03-12
### Added
- [#220] Maketarget for releasing images `make image-release`

## [v9.6.0](https://github.com/cloudogu/makefiles/releases/tag/v9.6.0) 2025-02-25
### Added
- [#216] Custom Maketarget for updating version numbers

## [v9.5.3](https://github.com/cloudogu/makefiles/releases/tag/v9.5.3) 2025-01-22
### Fixed
- [#214] removed double-quotes from variable-declaration in k8s.mk

## [v9.5.2](https://github.com/cloudogu/makefiles/releases/tag/v9.5.2) 2025-01-15
### Added
 - [#201] prerelease make step for testing on stageing tests
 
## [v9.5.1](https://github.com/cloudogu/makefiles/releases/tag/v9.5.1) 2025-01-14
### Fixed
- Fixed Typo in Regex for finding current dogu-build-lib-Version
- Append datetime to version for prerelease namespaces

### Changed
- change unittest-report generation from xml to json to generate valid report files for jenkins [#194]
- possibility to pass DRY_RUN parameter to "make dogu-release" target [#209]
- use "make dogu-release DRY_RUN=true" to start a dry-run release [#209]

## [v9.5.0](https://github.com/cloudogu/makefiles/releases/tag/v9.5.0) 2024-12-10
### Added
- Create Release-note Entry for new version during "make dogu-release" [#203]
- New make target "update-build-libs" to get newest version of build libs for jenkins pipeline [#203]

## [v9.4.0](https://github.com/cloudogu/makefiles/releases/tag/v9.4.0) 2024-11-25
### Added
- [#205] make step for prereleasing dogu

## [v9.3.2](https://github.com/cloudogu/makefiles/releases/tag/v9.3.2) 2024-10-18
### Changed
- Use v2 api version for k8s dogu deployment [#198] 

## [v9.3.1](https://github.com/cloudogu/makefiles/releases/tag/v9.3.1) 2024-10-11
### Changed
- Update go linter to 1.61.0 to support go 1.23
- use go 1.23 as default for linting
- use go 1.23 as default for builds

## [v9.2.1](https://github.com/cloudogu/makefiles/releases/tag/v9.2.1) 2024-09-05
### Fixed
- Add missing yq dependency on docker-build target

## [v9.2.0](https://github.com/cloudogu/makefiles/releases/tag/v9.2.0) 2024-08-28
### Added
- Add make target `govulncheck` to scan go repositories for vulnerabilities using [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)

### Changed
- `bats.mk`: 
  - Raise BATS image version to 1.11.0
  - set BATS's /workspace directory as a safe git directory to avoid the git error `detected dubious ownership`

### Fixed
- Remove Docker warning about potentially missing ARG default values [#190]

## [v9.1.0](https://github.com/cloudogu/makefiles/releases/tag/v9.1.0) 2024-06-28
### Added
- Add support for remote runtimes and container-registries for k8s-make-targets [#188]
  - The make-targets for k8s like dogu-`build`, `helm-apply` or `component-apply` now support deploying to remote kubernetes-clusters

## [v9.0.5](https://github.com/cloudogu/makefiles/releases/tag/v9.0.5) 2024-05-23
### Changed
- update Go version to 1.22 (for `make compile` and `make static analysis`) [#186]
- update Go linter to 1.58.2 [#185]

### Fixed
- Fix false positive during Go linting with Go version 1.22 [#186]

## [v9.0.4](https://github.com/cloudogu/makefiles/releases/tag/v9.0.4) 2024-04-19
### Fixed
- [#180] Properly delete previous helm packages to mitigate error where helm secrets get too big.
- Update CONTROLLER_GEN_VERSION to v0.14.0 to avoid panic during manifest-run when using go1.22 [#178]

## [v9.0.3](https://github.com/cloudogu/makefiles/releases/tag/v9.0.3) 2024-03-18
### Changed
- Pick up mockery version when the version was defined before including `mocks.mk`
  - it is no longer necessary to set the version variable `MOCKERY_VERSION` _after_ including `mocks.mk`. Instead the variable can be overwritten before the include.

### Fixed
- Update [Mockery](https://github.com/vektra/mockery) to v2.42.1 to avoid error messages during mock generation [#176]
  - these error messages occurred only with very recent Golang versions like Go 1.22. No errors were shown with Go 1.21

## [v9.0.2](https://github.com/cloudogu/makefiles/releases/tag/v9.0.2) 2024-01-18
### Fixed
- Remove duplicate version-tag from Dogu-Image in ks8-dogu.mk [#174]
- Set the yq output to YAML (instead of JSON)
  - This was changed for JSON-inputs in YQ v4.32.1 (see https://github.com/mikefarah/yq/issues/1608)

## [v9.0.1](https://github.com/cloudogu/makefiles/releases/tag/v9.0.1) 2023-12-01
### Changed
- Make the targets for generate and copy manifests configurable. External components have to override them with empty values because they do not have CRDs in go-code. [#172]
- Make the target to importing images configurable. Components with own images to build should override `IMAGE_IMPORT_TARGET` with `image-import`. [#172]
- Make the target to check all environment variables configurable. Components with own images to build should override `CHECK_VAR_TARGETS` with `check-all-vars`. [#172] 

### Fixed
- fixes wrong container image version `latest` during `image-import` [#172]
- the k8s/CRD target `helm-package-release` renames to `helm-package` in order to harmonize with `crd-helm-package`
- the k8s/CRD target `manifests` honors now the variable `HELM_CRD_SOURCE_DIR` if set to a different value

### Added
- runs k8s/CRD target `crd-add-labels` by default after the CRD generation target `manifest`

## [v9.0.0](https://github.com/cloudogu/makefiles/releases/tag/v9.0.0) 2023-11-30
Breaking change ahead! [#170]

This release cleans up lots of K8s targets and renames targets and variables in a more matching manner. 
Please take the time to revise the changes for your project if you use them after a major version upgrade.

### Changed

#### General K8s and k8s dogu-related
- the k8s variable `IMAGE_DEV` no longer contains a version tag because it makes editing YAML files easier
  - you can append `${VERSION}` as it should already be defined in your main makefile.
- k8s tool versions are now replaceable by these variables
  - `BINARY_YQ_4_VERSION`, `BINARY_HELM_VERSION`, and `CONTROLLER_GEN_VERSION` can now be customized if needed
    - simply set these variables before the inclusion of any `k8s*.mk` files
  - the corresponding path and version variables move to the same place in `k8s.mk` for better maintenance experience
- the variable `K8S_RESOURCE_TEMP_FOLDER` no longer contains a `make` subdirectory to simplify the directory structure in `target/`
- the k8s/dogu variable `DOGU_JSON_DEV_FILE` is no longer a relative path but absolute
- The k8s/dogu target `k8s-create-temporary-resource` renames to `create-dogu-resource`
  - its output can be optionally defined by setting `K8S_RESOURCE_DOGU` but defaults to `target/k8s/${ARTIFACT_ID}.yaml

#### Helm / components
- the k8s/helm target `helm-generate-chart` renames to `helm-generate`
  - `helm-generate` also provides now optional post-exec targets by setting `HELM_POST_GENERATE_TARGETS`
- the k8s/helm target `helm-apply` also executes `image-import`
  - this target also allows now optional pre-exec targets by setting `HELM_PRE_APPLY_TARGETS`
- the k8s/helm target `helm-chart-import` also executes `image-import`
- these overridable variables rename to their respective counterparts:
  - `K8S_HELM_TARGET` to `HELM_TARGET_DIR`
  - `K8S_HELM_RESSOURCES` to `HELM_SOURCE_DIR`
  - `K8S_HELM_ARTIFACT_NAMESPACE` to `HELM_ARTIFACT_NAMESPACE`

#### Helm-CRD
- the k8s/crd targets `manifests` and `generate` are no longer specific to the controller implementation
  - `manifests` can be found by including `build/make/k8s-crd.mk`
    - this target also allows now optional post-exec targets by setting `CRD_POST_MANIFEST_TARGETS`
  - `generate` can be found by including `build/make/k8s-controller.mk`
- the k8s/crd target `crd-helm-generate-chart` renames to `crd-helm-generate` and executes prior two checks: `validate-crd-chart`, `validate-crd`
  - `crd-helm-generate` allows also now optional post-exec targets by setting `K8S_POST_CRD_HELM_GENERATE_TARGETS`

#### k8s controller
- the k8s/controller target `generate` renames to `generate-deepcopy` for better understandability
 
### Removed
- the k8s targets `k8s-delete`, `k8s-generate`, and `k8s-apply` are removed in favor of Helm targets
  - along with these targets, the variables `K8S_PRE_GENERATE_TARGETS`, `PRE_APPLY_TARGETS`, `K8S_POST_GENERATE_TARGETS` are removed
  - instead these targets take their place: `HELM_PRE_GENERATE_TARGETS`, `HELM_PRE_APPLY_TARGETS`/`COMPONENT_PRE_APPLY_TARGETS`, `HELM_POST_GENERATE_TARGETS`
- the k8s/controller target `k8s-create-temporary-resource` which used to produce monolithic YAML resources is removed

### Added
- the k8s target `check-all-vars` executes now also the `check-k8s-image-env-var` check
- the k8s/helm targets `${HELM_TARGET_DIR}/Chart.yaml` (and thus `helm-generate`) may execute pre-targets configured in the new variable `HELM_PRE_GENERATE_TARGETS`
  - this target also checks with `validate-chart` if a source Helm `Chart.yaml` exists
- the k8s/helm target `copy-helm-files` copies all Helm files (including `Chart.yaml`) from the source directory to `target/k8s/helm`
  ${COMPONENT_PRE_APPLY_TARGETS}
- adds k8s/crd target `validate-crd-chart` to check for a source CRD `Chart.yaml`
- adds k8s/crd target `validate-crd` to check if `K8S_CRD_COMPONENT_SOURCE` was properly set
- adds k8s/crd target `crd-helm-lint` to lint the CRD's Helm chart
- adds k8s/component target `helm-lint` to lint the component's Helm chart

## [v8.8.0](https://github.com/cloudogu/makefiles/releases/tag/v8.8.0) 2023-11-21
### Added
- [#168] Publish targets for yarn to run publish tasks in a unified way
  - update the variable NODE_VERSION to define the used version of nodeJs (default: 8)
  - new target `node-release` to start the release for a node package

## [v8.7.3](https://github.com/cloudogu/makefiles/releases/tag/v8.7.3) 2023-10-20
### Fixed
- [#166] use --no-cache in dogu-cve-release 
- [#166] make fixed CVE-list unique

## [v8.7.2](https://github.com/cloudogu/makefiles/releases/tag/v8.7.2) 2023-10-20
### Fixed
- [#164] make cve severity configurable

## [v8.7.1](https://github.com/cloudogu/makefiles/releases/tag/v8.7.1) 2023-10-12
### Fixed
- [#162] fix coder build if secrets dir does not exist

## [v8.7.0](https://github.com/cloudogu/makefiles/releases/tag/v8.7.0) 2023-10-06
### Changed
- [#159] Update Helm binary to 3.13
- [#160] Add more Helm support
  - new `install-helm` phony target enables preparing Helm calls outside the makefile
  - update Helm chart dependencies in order to have dependencies after generating a proper chart 

## [v8.6.0](https://github.com/cloudogu/makefiles/releases/tag/v8.6.0) 2023-10-06
### Changed
- [#154] Make the `image-import` for k8s components and controllers configurable.
  - With this change k8s-components do not have to create own wrapper targets for apply task without the `image-import`. They must override `PRE_APPLY_TARGETS` with an empty string and can use regular targets like `helm-apply` or `component-apply`.
- [#158] Changed Component CR generation. Components can now use the variable `COMPONENT_DEPLOY_NAMESPACE` that will be used as the field `deployNamespace` in the CR.

## [v8.5.1](https://github.com/cloudogu/makefiles/releases/tag/v8.5.1) 2023-10-05
### Fixed
- [#156] fix detection of podman and docker in coder
- [#156] fix detection of coder user

## [v8.5.0](https://github.com/cloudogu/makefiles/releases/tag/v8.5.0) 2023-09-27
### Added
- [#152] Add make targets for generating and packaging helm-charts for CRDs of ces-components.

## [v8.4.0](https://github.com/cloudogu/makefiles/releases/tag/v8.4.0) 2023-09-21
### Added
- [#145] Add make targets and shell script to support Coder use-cases

## [v8.3.0](https://github.com/cloudogu/makefiles/releases/tag/v8.3.0) 2023-09-19
### Changed
- [#150] Set bash as default shell in `k8s.mk`.
- Add stage `production` as default variable in `k8s.mk`.
- Template `{{ .Namespace }}` from the resource only in the non helm dev target `k8s-apply` with the current namespace.
  When creating a helm chart use `{{ .Release.Namespace }}` for the current namespace at deploy time.

## [v8.2.0](https://github.com/cloudogu/makefiles/releases/tag/v8.2.0) 2023-09-15
### Added
- [#143] Add release target `dogu-cve-release` for dogus if a simple rebuild fixes critical CVEs.
  - The target can be executed with a `DRY_RUN` environment variable for added developer experience.
- Add missing K8s and bats target descriptions on the [README.md](README.md) 

## [v8.1.0](https://github.com/cloudogu/makefiles/releases/tag/v8.1.0) 2023-09-15
### Removed
- [#147] Remove Dummy-Chart-Dependencies from Helm-Chart-Generation

## [v8.0.0](https://github.com/cloudogu/makefiles/releases/tag/v8.0.0) 2023-09-12
### Added
- [#141] Add target to generate, apply etc. components resources.
  - Because of the new dev proxy registry image tags will now receive a `-dev` suffix to avoid getting a version that matches tags in the remote registry. This prevents the registry proxy to pull the remote image. The random make variable `IMAGE_DEV` is now part of the `k8s-component.mk` and projects no longer need to override it.

**Breaking change ahead!**

### Changed
- Changed name of component targets for better readability.
  - Keep in mind to update affected targets in build pipelines. 

## [v7.13.1](https://github.com/cloudogu/makefiles/releases/tag/v7.13.1) 2023-09-01
### Fixed
- [#139] Use `yq` from `bin` instead of the host machine to fix pipeline errors.

## [v7.13.0](https://github.com/cloudogu/makefiles/releases/tag/v7.13.0) 2023-08-31
### Fixed
- [#137] Package generated chart-dependencies in helm-chart
### Changed
- [#135] Updated controller-gen to v0.13.0

## [v7.12.1](https://github.com/cloudogu/makefiles/releases/tag/v7.12.1) 2023-08-31
### Fixed
- [#133] Added missing template-file `k8s-helm-temp-chart.yaml`

## [v7.12.0](https://github.com/cloudogu/makefiles/releases/tag/v7.12.0) 2023-08-23
### Added
- [#131] Support optional Helm chart dependencies during `k8s-helm-package-release`
   - Please note, that the dependency charts will be created on the fly. The created Helm package will not contain the dependency charts.
- [#131] the target `k8s-helm-init-chart` helps to create a file `k8s/helm/Chart.yaml`
   - please note, that an existing file will be overwritten.

### Changed
- [#131] Add further additional Helm command arguments variables. All of these variables are optional:
   - `BINARY_HELM_ADDITIONAL_PUSH_ARGS` for `helm push`
   - `BINARY_HELM_ADDITIONAL_PACK_ARGS` for `helm package`
   - `BINARY_HELM_ADDITIONAL_UNINST_ARGS` for `helm uninstall`
   - `BINARY_HELM_ADDITIONAL_UPGR_ARGS` for `helm upgrade`

### Fixed
- Rename the additional Helm command argument variable `ADDITIONAL_HELM_APPLY_ARGS` to `BINARY_HELM_ADDITIONAL_UPGR_ARGS`
- [#131] avoid to re-pack a Helm package from a previous `k8s-helm-package-release` run
   - instead the older copy of the Helm package will be deleted prior the actual Helm package creation

## [v7.11.0](https://github.com/cloudogu/makefiles/releases/tag/v7.11.0) 2023-08-22
### Added
- [#129] Instead of just copy the chart.yaml the whole chart will be copied from the `k8s` to the artifact.
  - Added additional helm args to configure definitions of helm values.

### Fixed
- [#115] Use labels `app: ces` for Dogu-CRs.

## [v7.10.0](https://github.com/cloudogu/makefiles/releases/tag/v7.10.0) 2023-07-07
# Removed
- [#127] Remove helmify and just copy the release resource in the helm chart because the helmify generation does not fit with our name prefixes and does not recognize some properties like `publishNotReadyAddresses` from the service spec.

## [v7.9.0](https://github.com/cloudogu/makefiles/releases/tag/v7.9.0) 2023-07-06
### Added
- [#125] Differentiate dev & prod environments and add release target

## [v7.8.0](https://github.com/cloudogu/makefiles/releases/tag/v7.8.0) 2023-07-04
### Added
- [#123] Add make target to create (Helm-)Chart.yaml-template and use it in other helm targets

## [v7.7.0](https://github.com/cloudogu/makefiles/releases/tag/v7.7.0) 2023-06-30
### Added
- [#121] Add make targets for packaging Helm charts
- [#119] Add make targets for handling Helm charts

## [v7.6.0](https://github.com/cloudogu/makefiles/releases/tag/v7.6.0) 2023-06-14
### Added
- [#117] Script to generate sha256sum for a given url

## [v7.5.0](https://github.com/cloudogu/makefiles/releases/tag/v7.5.0) 2023-02-24
### Changed
- [#110] Update controller-gen to v0.11.3
- [#110] Update kustomize to v4.5.7
### Fixed
- [#111] Removed double import causing messy output

## [v7.4.0](https://github.com/cloudogu/makefiles/releases/tag/v7.4.0) 2023-02-16
### Added
- Make `MOCKERY_IGNORED` overridable
### Fixed
- [#107] `mock` target didn't work

## [v7.3.1](https://github.com/cloudogu/makefiles/releases/tag/v7.3.1) 2023-02-16
### Fixed
- [#107] debug output of `make mocks`

## [v7.3.0](https://github.com/cloudogu/makefiles/releases/tag/v7.3.0) 2023-02-16
### Added
- [#107] Create mocks with `make mocks`

## [v7.2.0](https://github.com/cloudogu/makefiles/releases/tag/v7.2.0) 2023-01-25
### Changed
- [#105] Use the environment variable `NAMESPACE` from the .env file to generate and apply resources to the cluster.
- [#103] Remove the environment variable `K8S_CLUSTER_ROOT`, because it is no longer needed.

## [v7.1.1](https://github.com/cloudogu/makefiles/releases/tag/v7.1.1) 2022-11-30
### Fixed
- [#101] revert Target directory variable to be relative because it produced errors and unexpected results in already existing projects

## [v7.1.0](https://github.com/cloudogu/makefiles/releases/tag/v7.1.0) 2022-11-28
## Changed
- [#98] Target directory variable is now absolute.

### Fixed
- [#99] Exclude vendor directory for source file changes.

## [v7.0.1](https://github.com/cloudogu/makefiles/releases/tag/v7.0.1) 2022-08-30
### Fixed
- Removed `vet` targets from k8s makefiles

## [v7.0.0](https://github.com/cloudogu/makefiles/releases/tag/v7.0.0) 2022-08-30

**Breaking change ahead!**

### Removed
- Removed `vet` target because `vet` is used in golangci-lint #94
    - Projects must specify the path in `sonar-project.properties` to the golanci-lint report instead of the vet report:
      `sonar.go.golangci-lint.reportPaths=target/static-analysis/static-analysis-cs.log`

### Fixed
- Fixed golangci-lint and added new linters #94
- Create folder `target/make/k8s` for target `k8s-create-temporary-resource` #93

## [v6.3.0](https://github.com/cloudogu/makefiles/releases/tag/v6.3.0) 2022-08-24
### Added
- Add makefile `bats.mk` to execute bats tests.

### Fixed
- Use `BINARY_YQ` target in `k8s-dogu.mk`

## [v6.2.1](https://github.com/cloudogu/makefiles/releases/tag/v6.2.1) 2022-08-24
### Fixed
- Fix order of imports and use native yq for `k8s-dogu.mk` 

## [v6.2.0](https://github.com/cloudogu/makefiles/releases/tag/v6.2.0) 2022-08-24
### Fixed
- Import `k8s.mk` in `k8s-dogu.mk` before var declaration and use yq as downloaded binary; #89

## [v6.1.0](https://github.com/cloudogu/makefiles/releases/tag/v6.1.0) 2022-08-12
### Changed
- Changed the way how integration-tests are executed: #87
  - The variable PACKAGES_FOR_INTEGRATION_TEST has been removed and should no longer be used
  - By default when running `make integration-test` all existing tests are executed (specifically: all unit tests)
  - You should now define a pattern for integration tests in the Variable `INTEGRATION_TEST_NAME_PATTERN`
    - Only tests which names are matching this pattern will be executed in `make integration-test`
    - Suggested Pattern: `INTEGRATION_TEST_NAME_PATTERN=.*_inttest$$`. 
    - With that pattern, only test functions which names are ending with `_inttest` are executed by `make integration-test`

### Removed
- The variable PACKAGES_FOR_INTEGRATION_TEST

## [v6.0.3](https://github.com/cloudogu/makefiles/releases/tag/v6.0.3) 2022-06-13
### Fixed
- Use consistent temporary yaml file names in k8s makefiles: #86

## [v6.0.2](https://github.com/cloudogu/makefiles/releases/tag/v6.0.2) 2022-06-07
### Changed
- Moved function `go-get-tool` from `dependencies-gomod.mk` to `variables.mk`
- Removed the `k8s-delete` target as requirement for the `build` target in `k8s-controller.mk` and `k8s-dogu.mk`

## [v6.0.1](https://github.com/cloudogu/makefiles/releases/tag/v6.0.1) 2022-05-30
### Fixed
- Fix shell error when executing `k8s-dogu.mk` target; #82
  - this error only occurs with GNU make 4.2 and earlier

## [v6.0.0](https://github.com/cloudogu/makefiles/releases/tag/v6.0.0) 2022-05-20
### Changed
- k8s.mk: Replaced docker image `.tar` rollout with `docker push`; #78
   - Users of k8s-related (non-dogu) targets need to add two things:
      1. Add a make variable of the local dev-image
         - Most likely this will look like `IMAGE_DEV=${K3CES_REGISTRY_URL_PREFIX}/${ARTIFACT_ID}:${VERSION}`
      2. They must replace `$(IMAGE)` references with `$(IMAGE_DEV)` when they are solely used inside a local dev cluster
   - this DOES NOT apply for dogus: The respective functionality works out-of-the-box by including `k8s-dogu.mk` as before
      - Anyhow, the referenced image inside the dogu descriptor changed under the hood 

### Added
- k8s.mk; #78
   - Added `check-etc-hosts` target to detect errors in the DNS resolution while pushing images to a local registry
   - Added `check-insecure-cluster-registry` target to detect errors in the local Docker configuration  while pushing images to a local registry

## [v5.2.0](https://github.com/cloudogu/makefiles/releases/tag/v5.2.0) 2022-05-09
### Changed
- Added variable `LINT_VERION` to `static-analysis.mk` to define the `golangci-lint` version used for the analysis; #77

## [v5.1.0](https://github.com/cloudogu/makefiles/releases/tag/v5.1.0) 2022-04-29
### Added
- Target `vet` performing a static go vet analysis; #70
- Makefiles for k8s (`k8s.mk`) dogus (`k8s-dogu.mk`) and controllers (`k8s-controller.mk`) containing everything to build, test and deploy 
these applications; #70

## [v5.0.0](https://github.com/cloudogu/makefiles/releases/tag/v5.0.0) 2022-03-09

**Heads-up:** This release removes obsolete Go dependency management files. All go dependency management should be conducted
with `go mod` by now.

### Added
- Default help target to print all available make targets; #71
- new method `go-get-tool` to conveniently download go tools without affecting the module of the current project; #73
  - call it like so: `$(call go-get-tool,$(YOUR_BINARY_TARGET),YOURGOTOOLURL)`
    - find an example call in `build/make/test-common.mk`
  - this feature introduces a project relative directory `.bin` which will contain your downloaded go tools
  - you may add a matching line to your `.gitignore` file to avoid adding it to your repository

### Changed
- go-junit-reporter is now being downloaded without affecting the project module; #73
- the removal routine in `make clean` expands to the new `.bin` go tool directory

### Removed
- Remove glide and go dep makefiles

## [v4.8.0](https://github.com/cloudogu/makefiles/releases/tag/v4.8.0) 2022-02-28
### Added
- create extensibility to change version of files not tracked by the makefiles; #68

## [v4.7.1](https://github.com/cloudogu/makefiles/releases/tag/v4.7.1) 2021-12-01
### Fixed
- Make grep regex work with grep v3.7; #66

## [v4.7.0](https://github.com/cloudogu/makefiles/releases/tag/v4.7.0) 2021-11-30
### Changed
- Make the nodejs version adjustable via NODE_VERSION variable; #64

## [v4.6.0](https://github.com/cloudogu/makefiles/releases/tag/v4.6.0) 2021-09-16
## Changed 
- Reworked Release-script. It is new also able to handle releases of non-dogus (#62)

## Added
- Added command to release go-tools (#62)

## [v4.5.0](https://github.com/cloudogu/makefiles/releases/tag/v4.5.0) 2021-04-06
### Changed
- The testing dependency `go-junit-reporting` is retrieved with `GO111MODULE=off go get...` to support all kinds of dependency managers (`gomod`, `dep`, `glide`)
- Use main as production releases branch if existent; #60

## [v4.4.0](https://github.com/cloudogu/makefiles/releases/tag/v4.3.1) 2021-03-18
### Changed
- make go build args configurable

### Added
- Debian package (un)deployment for focal (Ubuntu 20.04); #56

### Removed
- Debian package (un)deployment for xenial (Ubuntu 16.04); #56

## [v4.3.1](https://github.com/cloudogu/makefiles/releases/tag/v4.3.1) 2021-01-25
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
