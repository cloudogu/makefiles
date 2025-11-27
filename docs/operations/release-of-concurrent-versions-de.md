# Release von nebenläufigen Versionen

## Problem mit Standard-Release-Prozess
In einigen Projekten ist es nötig, dass mehrere Versionen gleichzeitig entwickelt und gewartet werden müssen.
Der Standard-Release-Prozess ist darauf ausgelegt aus dem develop-Branch ein Release zu erstellen und in dem main/master-Branch zu mergen.
Dies ist bei nebenläufigen Versionen nicht möglich, da sich sonst Konflikte auf dem develop- und main/master-Branch ergeben würden.

## Anpassungen im Projekt
Der Ablauf des Release für nebenläufige Versionen ist relativ ähnlich zu dem Standard-Release-Prozess.
Um weiterhin Gitflow verwenden zu können, kommen vier kleine Anpassungen an das Projekt hinzu:
1. Setzen der Variable `BASE_VERSION` in der Makefile
2. Erstellen eines Branches `BASE_VERSION/develop`, der auch remote verfügbar ist.
3. Erstellen eines Branches `BASE_VERSION/main`, der auch remote verfügbar ist.
4. Anpassen des Jenkinsfiles

### Setzen der BASE_VERSION
Die `BASE_VERSION` in den Makefiles gibt die langläufige Version an, die nebenläufig gepflegt wird. 
Ist ein Projekt bspw. schon auf der Version `7.4.3` und es sind noch Bugfixes an der Version `6.5.2` nötig, kann die `BASE_VERSION` auf `6.5` gesetzt werden.
Die Bennenung ist hauptsächlich für die Erstellung der neuen Branches in den nächsten Schritten wichtig.

### Erstellung neuer develop-Branch
Der neue develop-Branch für die nebenläufige Version muss `BASE_VERSION/develop` benannt werden. 
Dieser wird im Release-Prozess automatisch für gitflow gesetzt, wenn die `BASE_VERSION` in der `Makefile` eingetragen ist.

### Erstellung neuer main-Branch
Der neue main-Branch für die nebenläufige Version muss `BASE_VERSION/main` benannt werden.
Dieser wird im Release-Prozess automatisch für gitflow gesetzt, wenn die `BASE_VERSION` in der `Makefile` eingetragen ist.


### Anpassung Jenkinsfile
Im `Jenkinsfile` müssen die neuen Branches ausgelesen werden. 
Dadurch können sie später beim Abschluss des Release verwendet werden, sodass der release-Branch korrekt gemergt wird.
```groovy
stage('Finish Release') {
    productionReleaseBranch = makefile.determineGitFlowMainBranch(productionReleaseBranch)
    developmentBranch = makefile.determineGitFlowDevelopBranch()
    gitflow.finishRelease(releaseVersion, productionReleaseBranch, developmentBranch)
}
```

### Verwenden des nebenläufigen Release-Prozesses
Wenn die oben genannten Anpassungen vorgenommen wurden, kann ein Release wie gewohnt mithilfe eines eigenen Make-Targets erstellt werden:
```makefile
.PHONY: example-release
example-release: ## Interactively starts the release workflow for example project
	@echo "Starting git flow release..."
	@build/make/release.sh example project
```

