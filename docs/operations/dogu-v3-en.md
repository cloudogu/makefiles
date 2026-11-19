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

Like for `k8s-dogu.mk`, `RUNTIME_ENV`, `KUBE_CONTEXT_NAME` and `NAMESPACE` (see `k8s.mk`) control where the dogu is pushed and installed.
`dogu-apply` passes the values to cldk as `CLDK_DEV_*` variables:

| cldk variable             | Value                                                                           | e.g. with `RUNTIME_ENV=k3d`            |
|---------------------------|---------------------------------------------------------------------------------|----------------------------------------|
| `CLDK_DEV_REG`            | `IMAGE_PUSH_REGISTRY_HOST`                                                      | `localhost:5001`                       |
| `CLDK_DEV_CLUSTER_REG`    | `CES_REGISTRY_HOST`                                                             | `k3d-registry-proxy.localhost:5000`    |
| `CLDK_DEV_PLAIN_HTTP`     | `true`, except with `RUNTIME_ENV=remote`                                        | `true`                                 |
| `CLDK_DEV_DOGU_NAMESPACE` | with `RUNTIME_ENV=remote` `testing` (or `ci` with `ENVIRONMENT=ci`), else empty | empty (`doguNamespace` of `cldk.yaml`) |
| `CLDK_DEV_KUBE_CONTEXT`   | `KUBE_CONTEXT_NAME`                                                             | current context                        |
| `CLDK_DEV_KUBE_NAMESPACE` | `NAMESPACE`                                                                     | value of `NAMESPACE`                   |


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
An already installed `.bin/cldk` is not replaced automatically; delete it first.
