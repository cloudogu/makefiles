# Release of concurrent versions

## Problem with standard release process
In some projects, it is necessary to develop and maintain several versions simultaneously.
The standard release process is designed to create a release from the develop branch and merge it into the main/master branch.
This is not possible with concurrent versions, as it would otherwise cause conflicts on the develop and main/master branches.

## Adjustments to the project
The release process for concurrent versions is relatively similar to the standard release process.
In order to continue using Gitflow, four small adjustments need to be made to the project:
1. Set the variable `BASE_VERSION` in the Makefile.
2. Create a branch `BASE_VERSION/develop`, which is also available remotely.
3. Create a branch `BASE_VERSION/main`, which is also available remotely.
4. Update Makefiles to at least 10.5.0 on `BASE_VERSION/develop` and on `BASE_VERSION/main`
5. Adjust the Jenkinsfile.

### Setting the `BASE_VERSION`
The `BASE_VERSION` in the Makefiles specifies the long-running version that is maintained concurrently.
For example, if a project is already at version `7.4.3` and bug fixes are still needed for version `6.5.2`, the `BASE_VERSION` can be set to `6.5`.
The naming is mainly important for creating the new branches in the next steps.

### Creation of a new develop branch
The new develop branch for the concurrent version must be named `BASE_VERSION/develop`.
This is automatically set for gitflow in the release process if the `BASE_VERSION` is entered in the `Makefile`.
The Makefiles on this branch have to be at v10.5.0 or newer.

### Creating a new main branch
The new main branch for the concurrent version must be named `BASE_VERSION/main`.
This is automatically set for gitflow in the release process if the `BASE_VERSION` is entered in the `Makefile`.
The Makefiles on this branch have to be at v10.5.0 or newer.


### Adjusting Jenkinsfile
If the Jenkinsfile runs with the pipe-build-lib, no changes are necessary!

If the Jenkinsfile runs on the ces-build-lib, the new branches must be read out correctly in it.
This allows them to be used later when completing the release, so that the release branch is merged correctly.
First, make sure a `makefile` object exists (e.g. `makefiles = new Makefile(this)`). Then adjust the
`Finish Release" stage like this:
```groovy
stage('Finish Release') {
    productionReleaseBranch = makefile.determineGitFlowMainBranch()
#    Add the name of your project's production branch, if it is not "main"
#    productionReleaseBranch = makefile.determineGitFlowMainBranch("master")
    developmentBranch = makefile.determineGitFlowDevelopBranch()
    gitflow.finishRelease(releaseVersion, productionReleaseBranch, developmentBranch)
}
```
Furthermore, the ces-build-lib has to be at v5.1.0 or newer.

### Using the concurrent release process
Once the above adjustments have been made, a release can be created as usual using a custom make target, if not already existent (e.g. dogu-release):
```makefile
.PHONY: example-release
example-release: ## Interactively starts the release workflow for example project
	@echo "Starting git flow release..."
	@build/make/release.sh example-project
```
