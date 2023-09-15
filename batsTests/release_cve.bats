#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

setup() {
  export WORKDIR=/workspace
  export MAKE_DIR="${WORKDIR}"/build/make
  export PATH="${BATS_TMPDIR}:${PATH}"
  docker="$(mock_create)"
  ln -s "${docker}" "${BATS_TMPDIR}/docker"
  jq="$(mock_create)"
  ln -s "${jq}" "${BATS_TMPDIR}/jq"
  read="$(mock_create)"
  ln -s "${read}" "${BATS_TMPDIR}/read"
  release_script="$(mock_create)"
  ln -s "${release_script}" "${BATS_TMPDIR}/release"
}

teardown() {
  unset MAKE_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/docker"
  rm "${BATS_TMPDIR}/jq"
  rm "${BATS_TMPDIR}/read"
  rm "${BATS_TMPDIR}/release"
}

@test "source script with bash should return exit code 0" {
  run source "${MAKE_DIR}/release_cve.sh"

  assert_success
}

@test "diffArrays should print values which are in the first but not in the second array" {
  source "${MAKE_DIR}/release_cve.sh"

  run diffArrays "CVE-11111 CVE-22222 CVE-33333" "CVE-22222"

  assert_success
  assert_line "CVE-11111 CVE-33333"
}

@test "diffArrays should print nothing on equal arrays" {
  source "${MAKE_DIR}/release_cve.sh"

  local result
  result=$(diffArrays "CVE-11111 CVE-22222 CVE-33333" "CVE-11111 CVE-22222 CVE-33333")

  assert_equal "${result}" ""
}

@test "diffArrays should print nothing on empty arrays" {
  source "${MAKE_DIR}/release_cve.sh"

  local result
  result=$(diffArrays "" "")

  assert_equal "${result}" ""
}

@test "docker login should call the login sub command with provided globals" {
  source "${MAKE_DIR}/release_cve.sh"

  export USERNAME="user"
  export PASSWORD="password"
  export REGISTRY_URL="registry"

  run dockerLogin

  assert_success
  assert_equal "$(mock_get_call_num "${docker}")" "1"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "login registry -u user -p password"
}

@test "docker logout should call the logout sub command with registry globals" {
  source "${MAKE_DIR}/release_cve.sh"

  export REGISTRY_URL="registry"

  run dockerLogout

  assert_success
  assert_equal "$(mock_get_call_num "${docker}")" "1"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "logout registry"
}

@test "nameFromDogu should return the name from the dogu.json file" {
  source "${MAKE_DIR}/release_cve.sh"
  export DOGU_JSON_FILE="dogu.json"

  run nameFromDogu

  assert_success
  assert_equal "$(mock_get_call_num "${jq}")" "1"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Name ${DOGU_JSON_FILE}"
}

@test "versionFromDogu should return the name from the dogu.json file" {
  source "${MAKE_DIR}/release_cve.sh"
  export DOGU_JSON_FILE="dogu.json"

  run versionFromDogu

  assert_success
  assert_equal "$(mock_get_call_num "${jq}")" "1"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Version ${DOGU_JSON_FILE}"
}

@test "imageFromDogu should return the name from the dogu.json file" {
  source "${MAKE_DIR}/release_cve.sh"
  export DOGU_JSON_FILE="dogu.json"

  run imageFromDogu

  assert_success
  assert_equal "$(mock_get_call_num "${jq}")" "1"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Image ${DOGU_JSON_FILE}"
}

@test "jsonPropertyFromDogu should call jq with the dogu.json file global variable and the provided parameter" {
  source "${MAKE_DIR}/release_cve.sh"
  export DOGU_JSON_FILE="dogu.json"

  run jsonPropertyFromDogu "property"

  assert_success
  assert_equal "$(mock_get_call_num "${jq}")" "1"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r property ${DOGU_JSON_FILE}"
}

@test "readCredentialsIfUnset should not ask to enter credentials if they are set" {
  source "${MAKE_DIR}/release_cve.sh"
  export USERNAME="user"
  export PASSWORD="password"

  run readCredentialsIfUnset

  assert_success
  assert_equal "$(mock_get_call_num "${read}")" "0"
}

@test "parseTrivyJsonResult should call jq with given severity and result file" {
  source "${MAKE_DIR}/release_cve.sh"
  export PASSWORD="password"

  run parseTrivyJsonResult "severity" "result.json"

  assert_success
  assert_equal "$(mock_get_call_num "${jq}")" "1"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"severity\") | .VulnerabilityID] | join(\" \") result.json"
}

@test "runMain should not start release process if cve were added" {
  source "${MAKE_DIR}/release_cve.sh"
  export TRIVY_PATH="${BATS_TMPDIR}/trivy"
  export TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
  export TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
  export TRIVY_DOCKER_CACHE_DIR=/tmp/db
  export TRIVY_IMAGE_SCAN_FLAGS="--use this"

  export USERNAME="user"
  export PASSWORD="password"

  mock_set_output "${jq}" "jenkins" "1"
  mock_set_output "${jq}" "1.0.0" "2"
  mock_set_output "${jq}" "jenkins" "3"
  mock_set_output "${jq}" "1.0.0" "4"
  mock_set_output "${jq}" "CVE-1" "5"
  mock_set_output "${jq}" "jenkins" "6"
  mock_set_output "${jq}" "1.0.0" "7"
  mock_set_output "${jq}" "jenkins" "8"
  mock_set_output "${jq}" "1.0.0" "9"
  mock_set_output "${jq}" "CVE-1 CVE-2" "10"

  run runMain

  assert_equal "$(mock_get_call_num "${docker}")" "6"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "login registry.cloudogu.com -u user -p password"
  assert_equal "$(mock_get_call_args "${docker}" "2")" "pull jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "3")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "4")" "build . -t jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "5")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "6")" "logout registry.cloudogu.com"
  assert_equal "$(mock_get_call_num "${jq}")" "10"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "2")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "3")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "4")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "5")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_args "${jq}" "6")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "7")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "8")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "9")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "10")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_line "Abort release. Added new vulnerabilities:"
  assert_line "CVE-2"
  assert_failure "2"
}

@test "runMain should not start release process if no cve will be fixed" {
  source "${MAKE_DIR}/release_cve.sh"
  export TRIVY_PATH="${BATS_TMPDIR}/trivy"
  export TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
  export TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
  export TRIVY_DOCKER_CACHE_DIR=/tmp/db
  export TRIVY_IMAGE_SCAN_FLAGS="--use this"

  export USERNAME="user"
  export PASSWORD="password"

  mock_set_output "${jq}" "jenkins" "1"
  mock_set_output "${jq}" "1.0.0" "2"
  mock_set_output "${jq}" "jenkins" "3"
  mock_set_output "${jq}" "1.0.0" "4"
  mock_set_output "${jq}" "CVE-1 CVE-2" "5"
  mock_set_output "${jq}" "jenkins" "6"
  mock_set_output "${jq}" "1.0.0" "7"
  mock_set_output "${jq}" "jenkins" "8"
  mock_set_output "${jq}" "1.0.0" "9"
  mock_set_output "${jq}" "CVE-1 CVE-2" "10"

  run runMain

  assert_equal "$(mock_get_call_num "${docker}")" "6"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "login registry.cloudogu.com -u user -p password"
  assert_equal "$(mock_get_call_args "${docker}" "2")" "pull jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "3")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "4")" "build . -t jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "5")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "6")" "logout registry.cloudogu.com"
  assert_equal "$(mock_get_call_num "${jq}")" "10"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "2")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "3")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "4")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "5")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_args "${jq}" "6")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "7")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "8")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "9")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "10")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_line "Abort release. Fixed no new vulnerabilities"
  assert_failure "3"
}

@test "runMain should start release process if cves will be fixed without dry run option" {
  source "${MAKE_DIR}/release_cve.sh"
  export TRIVY_PATH="${BATS_TMPDIR}/trivy"
  export TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
  export TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
  export TRIVY_DOCKER_CACHE_DIR=/tmp/db
  export TRIVY_IMAGE_SCAN_FLAGS="--use this"
  export RELEASE_SH="${release_script}"

  export USERNAME="user"
  export PASSWORD="password"

  mock_set_output "${jq}" "jenkins" "1"
  mock_set_output "${jq}" "1.0.0" "2"
  mock_set_output "${jq}" "jenkins" "3"
  mock_set_output "${jq}" "1.0.0" "4"
  mock_set_output "${jq}" "CVE-1 CVE-2" "5"
  mock_set_output "${jq}" "jenkins" "6"
  mock_set_output "${jq}" "1.0.0" "7"
  mock_set_output "${jq}" "jenkins" "8"
  mock_set_output "${jq}" "1.0.0" "9"
  mock_set_output "${jq}" "CVE-1" "10"

  run runMain

  assert_equal "$(mock_get_call_num "${docker}")" "6"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "login registry.cloudogu.com -u user -p password"
  assert_equal "$(mock_get_call_args "${docker}" "2")" "pull jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "3")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "4")" "build . -t jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "5")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "6")" "logout registry.cloudogu.com"
  assert_equal "$(mock_get_call_num "${jq}")" "10"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "2")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "3")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "4")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "5")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_args "${jq}" "6")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "7")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "8")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "9")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "10")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_num "${release_script}")" "1"
  assert_equal "$(mock_get_call_args "${release_script}" "1")" "dogu-cve-release CVE-2 "
  assert_success
}

@test "runMain should start release process if cves will be fixed with dry run option" {
  source "${MAKE_DIR}/release_cve.sh"
  export TRIVY_PATH="${BATS_TMPDIR}/trivy"
  export TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
  export TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
  export TRIVY_DOCKER_CACHE_DIR=/tmp/db
  export TRIVY_IMAGE_SCAN_FLAGS="--use this"
  export RELEASE_SH="${release_script}"
  export DRY_RUN="true"

  export USERNAME="user"
  export PASSWORD="password"

  mock_set_output "${jq}" "jenkins" "1"
  mock_set_output "${jq}" "1.0.0" "2"
  mock_set_output "${jq}" "jenkins" "3"
  mock_set_output "${jq}" "1.0.0" "4"
  mock_set_output "${jq}" "CVE-1 CVE-2" "5"
  mock_set_output "${jq}" "jenkins" "6"
  mock_set_output "${jq}" "1.0.0" "7"
  mock_set_output "${jq}" "jenkins" "8"
  mock_set_output "${jq}" "1.0.0" "9"
  mock_set_output "${jq}" "CVE-1" "10"

  run runMain

  assert_equal "$(mock_get_call_num "${docker}")" "6"
  assert_equal "$(mock_get_call_args "${docker}" "1")" "login registry.cloudogu.com -u user -p password"
  assert_equal "$(mock_get_call_args "${docker}" "2")" "pull jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "3")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "4")" "build . -t jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "5")" "run -v ${TRIVY_CACHE_DIR}:/tmp/db -v /var/run/docker.sock:/var/run/docker.sock -v ${TRIVY_PATH}:/result aquasec/trivy --cache-dir ${TRIVY_DOCKER_CACHE_DIR} -f json -o /result/results.json image ${TRIVY_IMAGE_SCAN_FLAGS} jenkins:1.0.0"
  assert_equal "$(mock_get_call_args "${docker}" "6")" "logout registry.cloudogu.com"
  assert_equal "$(mock_get_call_num "${jq}")" "10"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "2")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "3")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "4")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "5")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_args "${jq}" "6")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "7")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "8")" "-r .Image dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "9")" "-r .Version dogu.json"
  assert_equal "$(mock_get_call_args "${jq}" "10")" "-rc [.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"CRITICAL\") | .VulnerabilityID] | join(\" \") /tmp/trivy/results.json"
  assert_equal "$(mock_get_call_num "${release_script}")" "1"
  assert_equal "$(mock_get_call_args "${release_script}" "1")" "dogu-cve-release CVE-2 true"
  assert_success
}
