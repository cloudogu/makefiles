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
4. Alle Makefiles auf 10.5.0 oder höher bringen, sowohl in `BASE_VERSION/develop` als auch in `BASE_VERSION/main`
5. Anpassen des Jenkinsfiles

### Setzen der `BASE_VERSION`
Die `BASE_VERSION` in den Makefiles gibt die langläufige Version an, die nebenläufig gepflegt wird. 
Ist ein Projekt bspw. schon auf der Version `7.4.3` und es sind noch Bugfixes an der Version `6.5.2` nötig, kann die `BASE_VERSION` auf `6.5` gesetzt werden.
Die Bennenung ist hauptsächlich für die Erstellung der neuen Branches in den nächsten Schritten wichtig.

### Erstellung neuer develop-Branch
Der neue develop-Branch für die nebenläufige Version muss `BASE_VERSION/develop` benannt werden. 
Dieser wird im Release-Prozess automatisch für gitflow gesetzt, wenn die `BASE_VERSION` in der `Makefile` eingetragen ist.
Die Makefiles auf diesem Branch müssen auf v10.5.0 oder höher sein.

### Erstellung neuer main-Branch
Der neue main-Branch für die nebenläufige Version muss `BASE_VERSION/main` benannt werden.
Dieser wird im Release-Prozess automatisch für gitflow gesetzt, wenn die `BASE_VERSION` in der `Makefile` eingetragen ist.
Die Makefiles auf diesem Branch müssen auf v10.5.0 oder höher sein.

### Anpassung Jenkinsfile
Falls die pipe-build-lib im Einsatz ist, ist kein Umbau des Jenkinsfiles nötig!

Falls die ces-build-lib zum Einsatz kommt, müssen die neuen Branches im `Jenkinsfile` ausgelesen werden.
Dadurch können sie später beim Abschluss des Release verwendet werden, sodass der release-Branch korrekt gemergt wird.
Zurerst muss sichergestellt sein, dass ein `makefile`-Objekt besteht (bspw. `makefile = new Makefile(this)`). Danach
muss die "Finish Release"-Stage folgendermaßen umgebaut werden:
```groovy
stage('Finish Release') {
    productionReleaseBranch = makefile.determineGitFlowMainBranch()
#    Hier den Namen des Production-Branches eintragen, falls er nicht "main" heißt
#    productionReleaseBranch = makefile.determineGitFlowMainBranch("master")
    developmentBranch = makefile.determineGitFlowDevelopBranch()
    gitflow.finishRelease(releaseVersion, productionReleaseBranch, developmentBranch)
}
```
Außerdem muss die ces-build-lib auf mindestens 5.1.0 aktualisiert werden.

### Verwenden des nebenläufigen Release-Prozesses
Wenn die oben genannten Anpassungen vorgenommen wurden, kann ein Release wie gewohnt mithilfe eines eigenen Make-Targets erstellt werden, falls nicht schon vorhanden (bspw. dogu-release):
```makefile
.PHONY: example-release
example-release: ## Interactively starts the release workflow for example project
	@echo "Starting git flow release..."
	@build/make/release.sh example project
```

