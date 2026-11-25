# Updating download checksums with Renovate

Renovate bumps `<PREFIX>_VERSION` in a Dockerfile but cannot update the checksum of the file that version points to.
`make update-checksums` (from `build/make/renovate.mk`) does that. Renovate runs it as a `postUpgradeTask`, so the new checksum lands in the same commit as the version bump and the PR stays auto-mergeable.

## Dockerfile convention

Every download gets three variables with the same prefix, one variable per `ENV` or `ARG` line:

```dockerfile
FROM registry.cloudogu.com/official/base:3.24.4-1 AS downloader
# renovate: datasource=github-tags depName=swagger-api/swagger-ui extractVersion=^v(?<version>.*)$
ENV SWAGGERUI_VERSION=5.35.0
ENV SWAGGERUI_URL=https://github.com/swagger-api/swagger-ui/archive/refs/tags/v${SWAGGERUI_VERSION}.zip
ENV SWAGGERUI_CHECKSUM=3d45cd8edc920a4a37f6c0d6d8b222c104c393ece1bc3ea5ff2bf37597044b50
RUN curl --fail --silent --show-error --location --retry 3 "${SWAGGERUI_URL}" -o /tmp/swagger-ui.zip \
 && echo "${SWAGGERUI_CHECKSUM}  /tmp/swagger-ui.zip" | sha256sum -c -
```

- `<PREFIX>_VERSION` is maintained by Renovate.
- `<PREFIX>_URL` builds the download URL from `${...}` references to variables defined earlier in the file. Renovate never touches it.
- `<PREFIX>_CHECKSUM` is the sha256 of the download, maintained by `make update-checksums`.
- `ENV A=1 \ B=2` on one line is not supported.
- Download in a separate stage and `COPY --from=` the result, so the variables do not end up in the final image.

## How `make update-checksums` works

For each file in `CHECKSUM_FILES` (default: `Dockerfile`):

1. Read all `ENV`/`ARG` variables from the working copy and from `HEAD` and expand `${...}` references in file order.
2. For every `<PREFIX>_CHECKSUM`, resolve `<PREFIX>_URL`. A missing URL or an unresolved variable is an error.
3. Skip the pair if the resolved URL is the same as in `HEAD`.
4. Otherwise download the URL over HTTPS (`curl --fail`, so HTTP errors fail the target) and compute the sha256.
5. Write the checksums only after all downloads succeeded. On any error, no file is changed.

Comparing against `HEAD` works on every branch (`develop`, `11.2/develop`, feature branches) and needs no Renovate templating.
Locally: bump the version, run `make update-checksums`, commit.

If a version bump is committed without running the target, `HEAD` already has the new URL and the stale checksum stays.
The Docker build then fails at `sha256sum -c`. Fix the checksum by hand.

## Dogu setup

`Makefile`:

```makefile
include build/make/renovate.mk
```

`renovate.json` package rule:

```json
{
  "description": "Update download checksums in Dockerfile",
  "matchManagers": ["custom.regex"],
  "matchFileNames": ["**/[Dd]ockerfile*"],
  "postUpgradeTasks": {
    "commands": ["make update-checksums"],
    "fileFilters": ["**/[Dd]ockerfile*"],
    "executionMode": "branch"
  }
}
```

The self-hosted Renovate needs `make update-checksums` in its `allowedCommands`.
