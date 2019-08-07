# makefiles
Makefiles für Cloudogu Projekte

Für Go-Builds gibt es ein modulares, generisches Makefile, welches [hier](https://github.com/cloudogu/makefiles) zu finden ist. Das Repo dient zur Vereinheitlichung unserer Builds, deshalb müssen alle neuen Go-Projekte dieses Makefile verwenden.

## Neues Projekt
Wird ein neues Projekt angelegt, so müssen einmalig das base-`Makefile` sowie das Verzeichnis `build/make` kopiert werden, ohne die relativen Pfade zu verändern; i.e. `build` **muss** neben `Makefile` im Projekt-Root liegen und das `make`-Verzeichnis enthalten.
Gibt es zu einem späteren Zeitpunkt ein neues Release der Makefiles, so kann auf diese Version geupdatet werden, in dem die Variable `MAKEFILES_VERSION` im Makefile gestetzt, und anschließend das Goal `update-makefiles` ausgeführt wird:

```
make upate-makefiles
```

Die Module des Makefiles liegen in `build/make` und müssen den Anforderungen entsprechend eingebunden werden.

### Beispiel: Go Build mit Glide und Debian-Package
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

Wird in diesem Falle z.B. das `package`-Goal ausgeführt, wird automatisch Glide zum Herunterladen der Abhängigkeiten verwendet, sowie ein Debian-Package mit dem Binary angelegt.

### Go Build mit Go Dep und tar.gz-Package
Verwendet man stattdessen dieses Makefile:

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

wird zum Herunterladen der Dependencies go dep verwendet. Außerdem wird statt eines Debian-Pakets ein tar.gz-Archiv mit dem Binary angelegt.

## Module

### variables.mk

Dieses Modult enthält einige generische Definitionen und sollte immer eingebunden werden.

### info.mk

Enthält das Goal `info`, welches allgemeine Informationen zum Build (z.B. Name des Branches, Commit-ID) ausgibt.

### dependencies_godep.mk

Enthält das Goal `dependencies` (welches aus dem `build`-Goal aufgerufen wird) und nutzt go dep zur Dependencyverwaltung

### dependencies_glide.mk

Das Gleiche wie `dependencies_godep.mk` jedoch wird Glide statt dep verwendet.

### build.mk

Enthält das `build`-Goal welches den Build in einem Docker-Container startet (Reproducible Build) und eine Checksumme des erstellten Binaries erzeugt.

### unit-test.mk

Startet generisch die unit tests. Das entsprechende Goal heißt `unit-test`.

### unit-test-docker-compose.mk

Das gleiche wie `unit-test.mk`; startet (und stoppt) jedoch eine docker-compose-Umgebung.

### static-analysis.mk

Führt die statische Code-Analyse abhängig von der Umgebung (CI-Server oder lokal) aus. Goal: `static-analysis`

### clean.mk

Enthält das `clean`-Goal.

### package-debian.mk

Das package-debian-Modul erstellt aus den Daten im `deb`-Verzeichnis sowie dem kompilierten Binary (sofern es eines gibt, eine Ausnahme bildet z.B. ces-commons) ein Debian-Paket und legt dieses in `target/deb` ab. Außerdem wird die Checksumme des Debian-Pakets berechnet.

### digital-signature.mk

Berechnet von allen im `target`-Verzeichnis liegenden Dateien die Checksumme, schreibt diese in eine Datei und signiert diese Datei anschließend.

#### prepare-package
Das package-debian Modul ermöglicht das Kopieren weiterer Dateien in das zu erstellende Debian-Paket. Dafür muss lediglich **nach dem Import von package-debian.mk** das Goal `prepare-package` angelegt bzw. überschrieben werden. Ein Beispiel aus der cesapp:


```
[...]
include build/make/package-debian.mk

prepare-package:
	@echo "Copying additional files to be added to deb package"	
	@install -m 0755 -d $(DEBIAN_TARGET_DIR)/data/etc/bash_completion.d/
	cp ${GOPATH}/src/github.com/cloudogu/cesapp/vendor/github.com/codegangsta/cli/autocomplete/bash_autocomplete ${DEBIAN_TARGET_DIR}/data/etc/bash_completion.d/cesapp
```

