#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function readCredentialsIfUnset() {
  if [ -z "${USERNAME}" ]; then
    echo "username is unset"
    while [[ -z ${USERNAME} ]]; do
      read -r -p "type username for ${REGISTRY_URL}: " USERNAME
    done
  fi
  if [ -z "${PASSWORD}" ]; then
    echo "password is unset"
    while [[ -z ${PASSWORD} ]]; do
      read -r -s -p "type password for ${REGISTRY_URL}: " PASSWORD
    done
  fi
}

function diffArrays() {
  local cveListX=("$1")
  local cveListY=("$2")
  local result=()

  local cveX
  # Disable the following shellcheck because the arrays are sufficiently whitespace delimited because of the jq parsing result.
  # shellcheck disable=SC2128
  for cveX in "${cveListX[@]}"; do
    local found=0
    local cveY
    echo "$cveX"
    for cveY in ${cveListY}; do
      [[ "${cveY}" == "${cveX}" ]] && {
        found=1
        break
      }
    done

    [[ "${found}" == 0 ]] && result+=("${cveX}")
  done

  echo "${result[@]}"
}

function dockerLogin() {
  docker login "${REGISTRY_URL}" -u "${USERNAME}" -p "${PASSWORD}"
}

function dockerLogout() {
  docker logout "${REGISTRY_URL}"
}

function nameFromDogu() {
  jsonPropertyFromDogu ".Name"
}

function imageFromDogu() {
  jsonPropertyFromDogu ".Image"
}

function versionsFromDogu() {
  jsonPropertyFromDogu ".Version"
}

function jsonPropertyFromDogu() {
  local property="${1}"
  jq -r "${property}" "${DOGU_JSON_FILE}"
}

function pullRemoteImage() {
  docker pull "$(imageFromDogu):$(versionFromDogu)"
}

function buildLocalImage() {
  docker build . -t "$(imageFromDogu):$(versionFromDogu)"
}

function scanImage() {
  docker run -v "${TRIVY_CACHE_DIR}":"${TRIVY_DOCKER_CACHE_DIR}" -v /var/run/docker.sock:/var/run/docker.sock -v "${TRIVY_PATH}":/result aquasec/trivy --cache-dir "${TRIVY_DOCKER_CACHE_DIR}" -f json -o /result/results.json image "${TRIVY_IMAGE_SCAN_FLAGS}" "$(imageFromDogu):$(versionFromDogu)"
}

function parseTrivyJsonResult() {
  local severity="${1}"
  local trivy_result_file="${2}"
  local cve_result=""
  cve_result=$(jq -rc "[.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"${severity}\") | .VulnerabilityID] | join(\" \")" "${trivy_result_file}")
  echo "${cve_result}"
}

REGISTRY_URL="registry.cloudogu.com"
DOGU_JSON_FILE="dogu.json"

CVE_SEVERITY="CRITICAL"

TRIVY_PATH="/tmp/trivy-dogu-cve-release-$(nameFromDogu)"
TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
TRIVY_DOCKER_CACHE_DIR=/tmp/db
TRIVY_IMAGE_SCAN_FLAGS=

USERNAME=""
PASSWORD=""

function run() {
  readCredentialsIfUnset
  dockerLogin

  mkdir -p "${TRIVY_PATH}" # Cache will not be removed after release. rm requires root because the trivy container only runs with root.
  pullRemoteImage
  scanImage
  remote_trivy_cve_list=$(parseTrivyJsonResult "${CVE_SEVERITY}" "${TRIVY_RESULT_FILE}")

  buildLocalImage
  scanImage
  local_trivy_cve_list=$(parseTrivyJsonResult "${CVE_SEVERITY}" "${TRIVY_RESULT_FILE}")

  dockerLogout

  local cve_in_local_but_not_in_remote
  cve_in_local_but_not_in_remote=$(diffArrays "${local_trivy_cve_list}" "${remote_trivy_cve_list}")
  if [[ -n "${cve_in_local_but_not_in_remote}" ]]; then
    echo "Abort release. Added new vulnerabilities:"
    echo "${cve_in_local_but_not_in_remote[@]}"
    exit 2
  fi

  local cve_in_remote_but_not_in_local
  cve_in_remote_but_not_in_local=$(diffArrays "${remote_trivy_cve_list}" "${local_trivy_cve_list}")
  if [[ -z "${cve_in_remote_but_not_in_local}" ]]; then
    echo "Abort release. Fixed no new vulnerabilities"
    exit 3
  fi

  build/make/release.sh "dogu-cve-release" "${cve_in_remote_but_not_in_local}"
}

# make the script only run when executed, not when sourced from bats tests
if [[ -n "${BASH_VERSION}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  USERNAME="${1}"
  PASSWORD="${2}"
  TRIVY_IMAGE_SCAN_FLAGS="${3:-""}"
  run
fi
