#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

setup() {
  export WORKDIR=/workspace
  export MAKE_DIR="${WORKDIR}"/build/make
  export CURL_CALLS="${BATS_TEST_TMPDIR}/curl_calls"

  # The curl stub writes the URL as file content, so the expected checksum is sha256(url).
  # URLs containing "broken" fail like curl --fail does on HTTP 404.
  mkdir "${BATS_TEST_TMPDIR}/bin"
  cat > "${BATS_TEST_TMPDIR}/bin/curl" << 'EOF'
#!/usr/bin/env bash
output=""
url=""
while test "$#" -gt 0; do
  case "$1" in
    --output | --retry | --proto | --proto-redir) test "$1" != "--output" || output="$2"; shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
echo "${url}" >> "${CURL_CALLS}"
case "${url}" in
  *broken*) echo "curl: (22) The requested URL returned error: 404" >&2; exit 22 ;;
esac
printf '%s' "${url}" > "${output}"
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/curl"
  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

  export REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir "${REPO}"
  cd "${REPO}"
  git init --quiet
}

commit_all() {
  git add --all
  git -c user.name=test -c user.email=test@example.com commit --quiet --message "test"
}

sha() {
  printf '%s' "$1" | sha256sum | cut -d' ' -f1
}

@test "recomputes the checksum when the version changed and leaves other lines untouched" {
  cat > Dockerfile << 'EOF'
FROM alpine AS downloader
# renovate: datasource=github-tags depName=swagger-api/swagger-ui
ENV SWAGGERUI_VERSION=5.35.0
ENV SWAGGERUI_URL=https://example.com/swagger-ui/v${SWAGGERUI_VERSION}.zip
ENV SWAGGERUI_CHECKSUM=old
RUN curl "${SWAGGERUI_URL}"
EOF
  commit_all
  sed -i 's/5.35.0/5.36.0/' Dockerfile

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_success
  assert_equal "$(cat Dockerfile)" "FROM alpine AS downloader
# renovate: datasource=github-tags depName=swagger-api/swagger-ui
ENV SWAGGERUI_VERSION=5.36.0
ENV SWAGGERUI_URL=https://example.com/swagger-ui/v\${SWAGGERUI_VERSION}.zip
ENV SWAGGERUI_CHECKSUM=$(sha https://example.com/swagger-ui/v5.36.0.zip)
RUN curl \"\${SWAGGERUI_URL}\""
}

@test "does not download when no URL changed" {
  cat > Dockerfile << 'EOF'
ENV APP_VERSION=1.0.0
ENV APP_URL=https://example.com/app-${APP_VERSION}.tar.gz
ENV APP_CHECKSUM=unchanged
EOF
  commit_all

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_success
  assert_file_not_exists "${CURL_CALLS}"
  assert_file_contains Dockerfile '^ENV APP_CHECKSUM=unchanged$'
}

@test "computes the checksum of a pair that does not exist in HEAD" {
  echo "FROM alpine" > Dockerfile
  commit_all
  cat >> Dockerfile << 'EOF'
ENV APP_VERSION=1.0.0
ENV APP_URL=https://example.com/app-${APP_VERSION}.tar.gz
ENV APP_CHECKSUM=
EOF

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_success
  assert_file_contains Dockerfile "^ENV APP_CHECKSUM=$(sha https://example.com/app-1.0.0.tar.gz)\$"
}

@test "only recomputes the pair whose URL changed" {
  cat > Dockerfile << 'EOF'
ENV ONE_VERSION=1.0.0
ENV ONE_URL=https://example.com/one-${ONE_VERSION}.zip
ENV ONE_CHECKSUM=one
ENV TWO_VERSION=2.0.0
ENV TWO_URL=https://example.com/two-${TWO_VERSION}.zip
ENV TWO_CHECKSUM=two
EOF
  commit_all
  sed -i 's/2.0.0/2.1.0/' Dockerfile

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_success
  assert_equal "$(cat "${CURL_CALLS}")" "https://example.com/two-2.1.0.zip"
  assert_file_contains Dockerfile '^ENV ONE_CHECKSUM=one$'
  assert_file_contains Dockerfile "^ENV TWO_CHECKSUM=$(sha https://example.com/two-2.1.0.zip)\$"
}

@test "resolves several variables in the URL and supports ARG" {
  cat > Dockerfile << 'EOF'
ARG MIRROR=https://mirror.example.com
ARG APP_VERSION=1.0.0
ARG APP_URL=${MIRROR}/app/${APP_VERSION}/app.zip
ARG APP_CHECKSUM=old
EOF
  commit_all
  sed -i 's/1.0.0/1.1.0/' Dockerfile

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_success
  assert_file_contains Dockerfile "^ARG APP_CHECKSUM=$(sha https://mirror.example.com/app/1.1.0/app.zip)\$"
}

@test "fails when a checksum has no URL" {
  cat > Dockerfile << 'EOF'
ENV APP_VERSION=1.0.0
ENV APP_CHECKSUM=old
EOF
  commit_all

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_failure
  assert_output --partial "APP_URL"
}

@test "fails when a variable in the URL cannot be resolved" {
  cat > Dockerfile << 'EOF'
ENV APP_URL=https://example.com/app-${UNKNOWN_VERSION}.zip
ENV APP_CHECKSUM=old
EOF
  commit_all

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_failure
  assert_output --partial "UNKNOWN_VERSION"
}

@test "fails and leaves the file unchanged when a download fails" {
  cat > Dockerfile << 'EOF'
ENV ONE_VERSION=1.0.0
ENV ONE_URL=https://example.com/one-${ONE_VERSION}.zip
ENV ONE_CHECKSUM=one
ENV TWO_VERSION=2.0.0
ENV TWO_URL=https://example.com/two-${TWO_VERSION}.zip
ENV TWO_CHECKSUM=two
EOF
  commit_all
  sed -i -e 's/1.0.0/1.1.0/' -e 's/2.0.0/broken/' Dockerfile
  local before
  before="$(cat Dockerfile)"

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_failure
  assert_output --partial "404"
  assert_equal "$(cat Dockerfile)" "${before}"
}

@test "fails outside of a git repository" {
  rm -rf .git
  cat > Dockerfile << 'EOF'
ENV APP_URL=https://example.com/app.zip
ENV APP_CHECKSUM=old
EOF

  run "${MAKE_DIR}/renovate.sh" update-checksums Dockerfile

  assert_failure
  assert_output --partial "not inside a git repository"
}
