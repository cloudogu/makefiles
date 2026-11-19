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

Wie bei `k8s-dogu.mk` steuern `RUNTIME_ENV`, `KUBE_CONTEXT_NAME` und `NAMESPACE` (siehe `k8s.mk`), wohin gepusht und installiert wird.
`dogu-apply` gibt die Werte als `CLDK_DEV_*`-Variablen an cldk weiter:

| cldk-Variable             | Wert                                                                            | z. B. bei `RUNTIME_ENV=k3d`            |
|---------------------------|---------------------------------------------------------------------------------|----------------------------------------|
| `CLDK_DEV_REG`            | `IMAGE_PUSH_REGISTRY_HOST`                                                      | `localhost:5001`                       |
| `CLDK_DEV_CLUSTER_REG`    | `CES_REGISTRY_HOST`                                                             | `k3d-registry-proxy.localhost:5000`    |
| `CLDK_DEV_PLAIN_HTTP`     | `true`, außer bei `RUNTIME_ENV=remote`                                          | `true`                                 |
| `CLDK_DEV_DOGU_NAMESPACE` | bei `RUNTIME_ENV=remote` `testing` (bzw. `ci` mit `ENVIRONMENT=ci`), sonst leer | leer (`doguNamespace` aus `cldk.yaml`) |
| `CLDK_DEV_KUBE_CONTEXT`   | `KUBE_CONTEXT_NAME`                                                             | aktueller Kontext                      |
| `CLDK_DEV_KUBE_NAMESPACE` | `NAMESPACE`                                                                     | Wert von `NAMESPACE`                   |


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
Ein bereits installiertes `.bin/cldk` wird nicht automatisch ersetzt; vorher löschen.
