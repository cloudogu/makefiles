# Developing v3 dogus with `dogu-v3.mk`

`build/make/dogu-v3.mk` integrates [cldk](https://github.com/cloudogu/cldk) into the makefiles.
The build and push logic of v3 dogus lives in cldk, the module installs cldk and calls it.

## Inclusion

```makefile
include build/make/variables.mk
# optional, for v2 dogus
include build/make/k8s-dogu.mk
include build/make/dogu-v3.mk
```

`variables.mk` is required. The module includes `k8s.mk` itself.

## Targets

| Target         | Description                                                                                              |
|----------------|----------------------------------------------------------------------------------------------------------|
| `install-cldk` | Downloads cldk in version `BINARY_CLDK_VERSION` to `.bin/cldk` and verifies the sha256 checksum.         |
| `dogu-apply`   | Runs `cldk dogu dev-push $(CLDK_DEV_PUSH_ARGS)`. Aborts if `STAGE` is `production` (default), see below. |

## Configuration

`dogu-apply` only runs in the development stage.
Set `STAGE=development` in the `.env` of the project or on the command line.
With `RUNTIME_ENV=remote`, `dogu-apply` first checks the docker login to `CES_REGISTRY_HOST` and asks for missing credentials (`check-docker-credentials`).

Like for `k8s-dogu.mk`, `RUNTIME_ENV`, `KUBE_CONTEXT_NAME` and `NAMESPACE` (see `k8s.mk`) control where the dogu is pushed and installed.
`dogu-apply` passes the values to cldk as `CLDK_DEV_*` variables:

| cldk variable             | Value                                                                           | e.g. with `RUNTIME_ENV=k3d`            |
|---------------------------|---------------------------------------------------------------------------------|----------------------------------------|
| `CLDK_DEV_REG`            | `IMAGE_PUSH_REGISTRY_HOST`                                                      | `localhost:5001`                       |
| `CLDK_DEV_CLUSTER_REG`    | `CES_REGISTRY_HOST`                                                             | `k3d-registry-proxy.localhost:5000`    |
| `CLDK_DEV_PLAIN_HTTP`     | `true`, except with `RUNTIME_ENV=remote`                                        | `true`                                 |
| `CLDK_DEV_DOGU_NAMESPACE` | with `RUNTIME_ENV=remote` `testing` (or `ci` with `ENVIRONMENT=ci`), else empty | empty (`doguNamespace` of `cldk.yaml`) |
| `CLDK_DEV_KUBE_CONTEXT`   | `KUBE_CONTEXT_NAME`                                                             | current context                        |
| `CLDK_DEV_KUBE_NAMESPACE` | `NAMESPACE`, `ecosystem` if `NAMESPACE` is not set                              | value of `NAMESPACE`                   |


Each `CLDK_DEV_*` variable can be set in the environment or in the `.env` and then takes precedence;
flags in `CLDK_DEV_PUSH_ARGS` take precedence over everything.
See the [`cldk dogu dev-push` reference](https://github.com/cloudogu/cldk/blob/develop/docs/operations/dogu_dev_push_reference_en.md).

| Variable                    | Default                              | Description                                    |
|-----------------------------|--------------------------------------|------------------------------------------------|
| `BINARY_CLDK`               | `$(UTILITY_BIN_PATH)/cldk`           | Path of the cldk binary                        |
| `BINARY_CLDK_VERSION`       | `1.0.0`                              | cldk version to install                        |
| `BINARY_CLDK_URL`           | GitHub release asset (`linux_amd64`) | Download URL of the cldk archive               |
| `BINARY_CLDK_SUM`           | sha256 of the `linux_amd64` archive  | Checksum of the archive                        |
| `BINARY_CLDK_ARCHIVE_PATH`  | `cldk`                               | Path of the binary inside the archive          |
| `BINARY_CLDK_ARCHIVE_STRIP` | `0`                                  | Leading folders to strip from the archive path |
| `CLDK_DEV_PUSH_ARGS`        | empty                                | Additional arguments for `cldk dogu dev-push`  |

Example:

```shell
make dogu-apply CLDK_DEV_PUSH_ARGS=--dry-run
```

When changing `BINARY_CLDK_VERSION`, `BINARY_CLDK_SUM` must be changed as well (see `checksums.txt` of the cldk release).
An installed `.bin/cldk` with a different version is removed and downloaded again on the next call.

## Release

`make dogu-release` (from `release.mk`) starts the release of v3 dogus as well.
If the project contains a `cldk.yaml`, the dogu is released as v2 and v3 dogu at once (Doppel-Release).
This needs [yq v4](https://github.com/mikefarah/yq): `.bin/yq` (via `make install-yq`, needs Go) or yq in the `PATH`.

1. After the question "Release the v2 dogu as well?" (`y`) and the new v2 dogu version (e.g. `3.96.4-4`), the release asks for the new chart version.
   It must have the form `MAJOR.MINOR.PATCH` (no pre-release) and be greater than the current `version` in the
   `Chart.yaml`, otherwise the release aborts.
2. In the `Chart.yaml` (directory `chart` from the `cldk.yaml`, default `k8s/helm`):
   - `version` = new chart version,
   - `appVersion` = app part of the v2 dogu version (`3.96.4-4` → `3.96.4`).
3. In the `cldk.yaml` the `tag` of the image named like the dogu (`name` in the `Chart.yaml`) is set to the new v2 dogu
   version. A missing `tag` is added.
4. Both files are committed together with the other version changes.
5. The CHANGELOG section `## [v<v2 dogu version>]` gets the line `Chart-Version: <chart version>`.

The image tag is only maintained in the `cldk.yaml`.
`mirror-patch-tpl.yaml` and `values.yaml` of the chart stay unchanged.
cldk rewrites the image references via the `mirror-patch-tpl.yaml` when pushing the chart.
To keep both files up to date in the repository as well, the dogu can update them in its `release_args.sh`.

Example for Nexus:

```bash
#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

mirrorPatchTemplate="k8s/helm/mirror-patch-tpl.yaml"
values="k8s/helm/values.yaml"

update_versions_modify_files() {
  local newReleaseVersion="${1}"

  TAG="${newReleaseVersion}" ./.bin/yq -i '.values.images.nexus |= sub(":[^:]+$", ":" + strenv(TAG))' "${mirrorPatchTemplate}"
  TAG="${newReleaseVersion}" ./.bin/yq -i '.nexus.image.tag = strenv(TAG)' "${values}"
}

update_versions_stage_modified_files() {
  git add "${mirrorPatchTemplate}" "${values}"
}
```

### Release only the v3 dogu

The chart can be released without a new v2 dogu version, e.g. for a change of the chart only:

- For a double release dogu, the release first asks "Release the v2 dogu as well?"; with `n` only the chart is released.
- A dogu without `dogu.json` (v3 dogu only) is always released this way; the release only asks for the chart version.
- `dogu-cve-release` always releases both (double release), because the new image needs a new v2 dogu version.

Then only the `version` in the `Chart.yaml` is updated; `appVersion`, `cldk.yaml`, `dogu.json`, `Dockerfile` and the
`VERSION` in the `Makefile` stay unchanged (the extension points of `release_args.sh` are skipped as well).
The release branch is `release/chart/v<chart version>` (dry run `dryrun/chart/v<chart version>`), the CHANGELOG
section `## [chart/v<chart version>]`.

Without a `cldk.yaml` the release works as before.
