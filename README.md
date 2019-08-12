# makefiles
Makefiles for Cloudogu projects

This repository holds makefiles for building Cloudogu tools, especially those written in Go. They were created to standardize the build and release process. You should use them for every new tool you are developing in the Cloudogu environment.

## New Project
When creating a new project you have to import the `Makefile` and the `build` directory (with all its contents). While doing so you need to keep the directory structure, i.e. the `Makefile` and `build` folder need to be in the project's root folder.
When there is a new release of the Makefiles in the future, you can easily upgrade your Makefiles via setting the `MAKEFILES_VERSION` variable in the `Makefile` and executing the `update-makefiles` make target:

```
make update-makefiles
```

The `build/make` folder holds all Makefiles referenced by the `Makefile` in the root folder. This main `Makefile` can be adjusted to your needs. For example, if you want to build a Go project with glide and pack it into a .deb package you can adjust your `Makefile` in the following way:

### Example: Go Build with Glide and Debian-Package
```
ARTIFACT_ID=app
VERSION=0.1.2

MAKEFILES_VERSION= 

.DEFAULT_GOAL:=compile

include build/make/variables.mk
include build/make/info.mk
include build/make/dependencies_glide.mk
include build/make/build.mk
include build/make/unit-test.mk
include build/make/static-analysis.mk
include build/make/clean.mk
include build/make/package-debian.mk

```

If you use the `package` make target, your `Makefile` will automatically use glide for downloading dependencies, compiles and creates a .deb package including the binary afterwards.

### Go Build with Go Dep and tar.gz-Package
If you use this kind of `Makefile`, `go dep` will be used to fetch dependencies:

```
ARTIFACT_ID=app
VERSION=0.1.2

MAKEFILES_VERSION= 

.DEFAULT_GOAL:=compile

include build/make/variables.mk
include build/make/info.mk
include build/make/dependencies_godep.mk
include build/make/build.mk
include build/make/unit-test-docker-compose.mk
include build/make/static-analysis.mk
include build/make/clean.mk
include build/make/package-tar.mk
```

Also, a tar.gz-package will be created instead of a debian package.

## Modules

### variables.mk

This module holds generic definitions needed for all builds and should be always included.

### info.mk

This module holds the `info` target which prints general information about the build (e.g. name of the branch, commit ID).

### dependencies-godep.mk

This module holds the `dependencies` target, which is utilized by the `build` target. It uses `go dep` for fetching dependencies.

Include only one of the files: dependencies-godep.mk OR dependencies-glide.mk

### dependencies-glide.mk

This module holds the `dependencies` target, which is utilized by the `build` target. It uses `glide` for fetching dependencies.

Include only one of the files: dependencies-godep.mk OR dependencies-glide.mk

### build.mk

This module holds the `build` target, which starts the build inside a Docker container (to ensure reproducible builds). It also creates a checksum of the binary.

### unit-test.mk

This module ensures that you can start unit tests via the `unit-test` target.

Include only one of the files: unit-test.mk OR unit-test-docker-compose.mk

### unit-test-docker-compose.mk

This module ensures that you can start unit tests via the `unit-test` target, including an additional environment which is started and stopped using docker-compose.

Include only one of the files: unit-test.mk OR unit-test-docker-compose.mk

### static-analysis.mk

This module holds the `static-analysis` target for static code analysis. It automatically determines the working environment (local or CI).

### clean.mk

This module holds the `clean` target to clean your workspace.

### package-debian.mk

This module enables you to build a debian package from the local contents. The `package` target will compile the binary and create a .deb file which holds the contents in the `deb` folder and the binary.
The module also enables you to build a debian package without compiling, using the `debian` target.

Include only one of the files: package-debian.mk OR package-tar.mk

### package-tar.mk

This module lets you use the `package` target to pack a .tar archive.

Include only one of the files: package-debian.mk OR package-tar.mk

### digital-signature.mk

This module makes sure that a checksum is calculated for every file in the `target` folder and signs the checksum files.

### yarn.mk

This module enables you to use yarn via the `yarn-install` target.

### bower.mk

This module enables you to use bower via the `bower-install` target.