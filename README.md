# makefiles
Makefiles for Cloudogu projects

This repository holds makefiles for building Cloudogu tools, especially those written in Go. They were created to standardize the build and release process. You should use them for every new tool you are developing in the Cloudogu environment.

## Create a New Project or update it

When creating a new project you have to import the `Makefile` and the `build` directory (with all its contents). While doing so you need to keep the directory structure, i.e. the `Makefile` and `build` folder need to be in the project's root folder.

When there is a new release of the Makefiles in the future, you can easily upgrade your Makefiles via setting the `MAKEFILES_VERSION` variable in the `Makefile` and executing the `update-makefiles` make target:

```
make update-makefiles
```

Please note that there MUST NOT be done any changes within the `${BUILD_DIR}/make/` directory. Content within this directory may be removed and added during the update of the makefiles. Usually the way how the makefiles work can be modified by these to things:

1. overwriting Makefile variables
   - usually pre- or post-target variables like `POST_UNITTESTS`
   - often these can be overwritten with project specific make targets 
1. include only one of filial makefiles that provide the an exclusive build target defined in several files
   - f. i. `dependencies-godep` vs `dependencies-glide`

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

The exact golang container that is going to be used to compile Go code can be configured by overwriting the makefile variables `GOIMAGE` and `GOTAG` in the main `Makefile`. A different Go compiler version could be achieved with a line like this:

```
GOTAG=1.15.6-buster
```

This module also supports one optional Docker volume mount to the Golang container. The sureshot default mounts the host's `/tmp` to the container `/tmp`. A custom volume mount can be expressed by overwriting the makefile variable `CUSTOM_GO_MOUNT` in your main `Makefile` with the usual Docker volume syntax:

```makefile
CUSTOM_GO_MOUNT=-v /host/path/:/container/path
``` 

When building on Jenkins CI, make sure to mount a `/etc/passwd` file according to the Jenkins user (this file can be easily generated). This mounting is even easier with the help of the [ces-build-lib](https://github.com/cloudogu/ces-build-lib) `mountJenkinsUser()` step, like so:

```
new Docker(this)
 .image('golang:1.14.13')
 .mountJenkinsUser()
 .inside
``` 

### unit-test.mk

This module ensures that you can start unit tests via the `unit-test` target.

Include only one of the files: unit-test.mk OR unit-test-docker-compose.mk

### unit-test-docker-compose.mk

This module ensures that you can start unit tests via the `unit-test` target, including an additional environment which is started and stopped using docker-compose.

Include only one of the files: unit-test.mk OR unit-test-docker-compose.mk

### static-analysis.mk

This module holds the `static-analysis` target for static code analysis. It automatically determines the working environment (local or CI).

Static analysis is now powered by the official Golang containers in the very same ways as it is done in `build.mk`. Any container customizations can be applied in the same way to local static-analysis.

When running on Jenkins CI and to avoid configuration overhead it is possible to re-use  the same Golang container (that was used to compile the code) and embedd a static analysis stage there.

### clean.mk

This module holds the `clean` target to clean your workspace.

### package-debian.mk

This module enables you to build a debian package from the local contents. The `package` target will compile the binary and create a .deb file which holds the contents in the `deb` folder and the binary.
The module also enables you to build a debian package *without compiling a binary*, using the `debian` target. This makes sense for example if the debian file should consist only of configuration files.
The target `lint-deb-package` will show any errors or warnings for your built debian package.

Include only one of the files: package-debian.mk OR package-tar.mk

### deploy-debian.mk

This module enables you to deploy or undeploy the built deb package to/from the apt repository via the `deploy` respectively `undeploy` targets.

The variable `APT_REPO` determines, which repository should be used as a target. Currently, it supports the following values:
- `ces-premium`: The secured repositories are used
- any other value: The public repositories are used

If you want to use this module, you also have to include the `package-debian.mk` module!

#### Package requirements

You need a `deb` directory in order to successfully create a debian package. This directory is used to incorporate existing files and directories into the debian package. The minimum requirement for a valid debian package is a `control` file which you must place in `deb/DEBIAN/control`.

As an extended example, a proper directory could look like this:

```
deb/
 L DEBIAN/
 |  L control
 |  L postinst
 L etc/ 
    L config.file
```

Files which reside in `DEBIAN` will be subject to be stored in the `control` part of the debian package.
In turn, all other files and directories will be stored in the `data` part of the debian package. 

Please note when you are building a debian package that all files under `/deb/etc` will be named in a automatically generated file `conffiles`. Those files will be subject to debian's conflict management instead of overwriting crucial configuration files when said configuration files already exist (f. i. when a package is upgraded).

 

### package-tar.mk

This module lets you use the `package` target to pack a .tar archive.

Include only one of the files: package-debian.mk OR package-tar.mk

### digital-signature.mk

This module makes sure that a checksum is calculated for every file in the `target` folder and signs the checksum files.

### yarn.mk

This module enables you to use yarn via the `yarn-install` target.

### bower.mk

This module enables you to use bower via the `bower-install` target.

### release.mk

This module holds the `dogu-release` target for starting automated dogu releases.

Only include this module in dogu repositories!
