#!groovy

@Library('github.com/cloudogu/ces-build-lib@4.2.0')
import com.cloudogu.ces.cesbuildlib.*

// Creating necessary git objects
git = new Git(this, "cesmarvin")
git.committerName = 'cesmarvin'
git.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, git)
github = new GitHub(this, git)
changelog = new Changelog(this)
makefile = new Makefile(this)

// Configuration of repository
repositoryOwner = "cloudogu"
repositoryName = "makefiles"
project = "github.com/${repositoryOwner}/${repositoryName}"

// Configuration of branches
productionReleaseBranch = "master"
developmentBranch = "develop"
currentBranch = "${env.BRANCH_NAME}"

node('') {
    timestamps {
        stage('Checkout') {
            checkout scm
            make 'clean'
        }

        stage('Check Makefiles') {
            // Dry-run make to check for errors in Makefiles
            make '-n'
        }

        if (gitflow.isReleaseBranch()) {
            String controllerVersion = makefile.getVersion()
            String releaseVersion = "v${controllerVersion}".toString()

            stage('Finish Release') {
                gitflow.finishRelease(releaseVersion, productionReleaseBranch)
            }

            stage('Add Github-Release') {
                releaseId = github.createReleaseWithChangelog(releaseVersion, changelog, productionReleaseBranch)
            }
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}
