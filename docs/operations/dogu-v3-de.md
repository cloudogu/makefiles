# v3-Dogus mit `dogu-v3.mk` entwickeln

`build/make/dogu-v3.mk` bindet [cldk](https://github.com/cloudogu/cldk) in die Makefiles ein.
Die Build- und Push-Logik für v3-Dogus liegt in cldk, das Modul installiert cldk und ruft es auf.

## Einbinden

```makefile
include build/make/variables.mk
# optional, für v2-Dogus
include build/make/k8s-dogu.mk
include build/make/dogu-v3.mk
```

`variables.mk` wird benötigt. Das Modul bindet `k8s.mk` selbst ein.

## Targets

| Target         | Beschreibung                                                                                                    |
|----------------|-----------------------------------------------------------------------------------------------------------------|
| `install-cldk` | Lädt cldk in Version `BINARY_CLDK_VERSION` nach `.bin/cldk` und prüft die sha256-Checksumme.                    |
| `dogu-apply`   | Ruft `cldk dogu dev-push $(CLDK_DEV_PUSH_ARGS)` auf. Bricht ab, wenn `STAGE` `production` ist (Standard), s. u. |

## Konfiguration

`dogu-apply` läuft nur in der Development-Stage.
Dazu `STAGE=development` in der `.env` des Projekts oder auf der Kommandozeile setzen.
Bei `RUNTIME_ENV=remote` prüft `dogu-apply` vorher den Docker-Login an `CES_REGISTRY_HOST` und fragt fehlende Zugangsdaten ab (`check-docker-credentials`).

Wie bei `k8s-dogu.mk` steuern `RUNTIME_ENV`, `KUBE_CONTEXT_NAME` und `NAMESPACE` (siehe `k8s.mk`), wohin gepusht und installiert wird.
`dogu-apply` gibt die Werte als `CLDK_DEV_*`-Variablen an cldk weiter:

| cldk-Variable             | Wert                                                                            | z. B. bei `RUNTIME_ENV=k3d`            |
|---------------------------|---------------------------------------------------------------------------------|----------------------------------------|
| `CLDK_DEV_REG`            | `IMAGE_PUSH_REGISTRY_HOST`                                                      | `localhost:5001`                       |
| `CLDK_DEV_CLUSTER_REG`    | `CES_REGISTRY_HOST`                                                             | `k3d-registry-proxy.localhost:5000`    |
| `CLDK_DEV_PLAIN_HTTP`     | `true`, außer bei `RUNTIME_ENV=remote`                                          | `true`                                 |
| `CLDK_DEV_DOGU_NAMESPACE` | bei `RUNTIME_ENV=remote` `testing` (bzw. `ci` mit `ENVIRONMENT=ci`), sonst leer | leer (`doguNamespace` aus `cldk.yaml`) |
| `CLDK_DEV_KUBE_CONTEXT`   | `KUBE_CONTEXT_NAME`                                                             | aktueller Kontext                      |
| `CLDK_DEV_KUBE_NAMESPACE` | `NAMESPACE`, ohne `NAMESPACE` `ecosystem`                                       | Wert von `NAMESPACE`                   |


Jede `CLDK_DEV_*`-Variable kann in der Umgebung oder in der `.env` gesetzt werden und hat dann Vorrang;
Flags in `CLDK_DEV_PUSH_ARGS` haben Vorrang vor allem.
Siehe [Referenz zu `cldk dogu dev-push`](https://github.com/cloudogu/cldk/blob/develop/docs/operations/dogu_dev_push_reference_de.md).

| Variable                    | Standard                             | Beschreibung                                   |
|-----------------------------|--------------------------------------|------------------------------------------------|
| `BINARY_CLDK`               | `$(UTILITY_BIN_PATH)/cldk`           | Pfad des cldk-Binaries                         |
| `BINARY_CLDK_VERSION`       | `1.0.0`                              | Zu installierende cldk-Version                 |
| `BINARY_CLDK_URL`           | GitHub-Release-Asset (`linux_amd64`) | Download-URL des cldk-Archivs                  |
| `BINARY_CLDK_SUM`           | sha256 des `linux_amd64`-Archivs     | Checksumme des Archivs                         |
| `BINARY_CLDK_ARCHIVE_PATH`  | `cldk`                               | Pfad des Binaries im Archiv                    |
| `BINARY_CLDK_ARCHIVE_STRIP` | `0`                                  | Zu entfernende Ordnerebenen im Archivpfad      |
| `CLDK_DEV_PUSH_ARGS`        | leer                                 | Zusätzliche Argumente für `cldk dogu dev-push` |

Beispiel:

```shell
make dogu-apply CLDK_DEV_PUSH_ARGS=--dry-run
```

Wird `BINARY_CLDK_VERSION` geändert, muss auch `BINARY_CLDK_SUM` angepasst werden (siehe `checksums.txt` des cldk-Releases). 
Ein installiertes `.bin/cldk` mit abweichender Version wird beim nächsten Aufruf entfernt und neu geladen.

## Release

`make dogu-release` (aus `release.mk`) startet auch den Release von v3-Dogus.
Enthält das Projekt eine `cldk.yaml`, wird das Dogu gleichzeitig als v2- und v3-Dogu released (Doppel-Release).
Dafür wird [yq v4](https://github.com/mikefarah/yq) benötigt: `.bin/yq` (per `make install-yq`, braucht Go) oder yq im `PATH`.

1. Nach der Frage „Release the v2 dogu as well?“ (`y`) und der neuen v2-Dogu-Version (z. B. `3.96.4-4`) fragt der Release die neue Chart-Version ab.
   Sie muss die Form `MAJOR.MINOR.PATCH` haben (ohne Prerelease) und größer als die aktuelle `version` im `Chart.yaml`
   sein, sonst bricht der Release ab.
2. Im `Chart.yaml` (Verzeichnis `chart` aus der `cldk.yaml`, Standard `k8s/helm`):
   - `version` = neue Chart-Version,
   - `appVersion` = App-Anteil der v2-Dogu-Version (`3.96.4-4` → `3.96.4`).
3. In der `cldk.yaml` wird der `tag` des Images mit dem Dogu-Namen (`name` im `Chart.yaml`) auf die neue v2-Dogu-Version
   gesetzt. Fehlt der `tag`, wird er ergänzt.
4. Beide Dateien werden zusammen mit den übrigen Versionsänderungen committet.
5. Der CHANGELOG-Abschnitt `## [v<v2-Dogu-Version>]` bekommt die Zeile `Chart-Version: <Chart-Version>`.

Der Image-Tag wird nur in der `cldk.yaml` gepflegt. 
`mirror-patch-tpl.yaml` und `values.yaml` des Charts bleiben unverändert.
cldk schreibt die Image-Referenzen beim Push des Charts über die `mirror-patch-tpl.yaml` um.
Sollen beide Dateien auch im Repository aktuell sein, kann das Dogu sie in seiner `release_args.sh` anpassen.

Beispiel für Nexus:

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

### Release nur für das v3-Dogu

Das Chart kann ohne neue v2-Dogu-Version released werden, z. B. bei einer reinen Chart-Änderung:

- Bei einem Doppel-Release-Dogu fragt der Release zuerst „Release the v2 dogu as well?“; mit `n` wird nur das Chart
  released.
- Ein Dogu ohne `dogu.json` (nur v3-Dogu) wird immer so released; der Release fragt nur die Chart-Version ab.
- `dogu-cve-release` released immer beide (Doppel-Release), weil das neue Image eine neue v2-Dogu-Version braucht.

Dann wird nur die `version` im `Chart.yaml` hochgezogen; `appVersion`, `cldk.yaml`, `dogu.json`, `Dockerfile` und die
`VERSION` im `Makefile` bleiben unverändert (auch die Erweiterungspunkte aus `release_args.sh` entfallen).
Der Release-Branch heißt `release/chart/v<Chart-Version>` (Dry-Run `dryrun/chart/v<Chart-Version>`), der
CHANGELOG-Abschnitt `## [chart/v<Chart-Version>]`.

Ohne `cldk.yaml` läuft der Release wie bisher.
