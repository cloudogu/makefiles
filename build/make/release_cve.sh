#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function diffArrays {
  local I=("$1")
  local J=("$2")
  local RESULT=()

  for i in ${I}; do
    local FOUND=0
    for j in ${J}; do
      [[ "${j}" == "${i}" ]] && {
        FOUND=1
        break
      }
    done

    [[ $FOUND == 0 ]] && RESULT+=("$i")
  done

  echo "${RESULT[@]}"
}

dockerLogin() {
  local USERNAME="${1}"
  local PASSWORD="${2}"
  docker login "${REGISTRY_URL}" -u "${USERNAME}" -p "${PASSWORD}"
}

dockerLogout() {
  docker logout "${REGISTRY_URL}"
}

pullRemoteImage() {
  local IMAGE
  local VERSION
  IMAGE=$(jq -r .Image dogu.json)
  VERSION=$(jq -r .Version dogu.json)
  docker pull "${IMAGE}:${VERSION}"
}

buildLocalImage() {
  local IMAGE
  local VERSION
  IMAGE=$(jq -r .Image dogu.json)
  VERSION=$(jq -r .Version dogu.json)
  docker build . -t "${IMAGE}:${VERSION}"
}

scanImage() {
  local IMAGE
  local VERSION
  IMAGE=$(jq -r .Image dogu.json)
  VERSION=$(jq -r .Version dogu.json)
  docker run -v "${TRIVY_CACHE_DIR}":"${TRIVY_DOCKER_CACHE_DIR}" -v /var/run/docker.sock:/var/run/docker.sock -v "${TRIVY_PATH}":/result aquasec/trivy --cache-dir "${TRIVY_DOCKER_CACHE_DIR}" -f json -o /result/results.json image "${IMAGE}:${VERSION}"
}

parseTrivyJsonResult() {
  local SEVERITY="${1}"
  local TRIVY_RESULT_FILE="${2}"
  local CVE_RESULT=""
  CVE_RESULT=$(jq -rc "[.Results[] | select(.Vulnerabilities) | .Vulnerabilities | .[] | select(.Severity == \"${SEVERITY}\") | .VulnerabilityID] | join(\" \")" "${TRIVY_RESULT_FILE}" )
  echo "${CVE_RESULT}"
}

REGISTRY_URL="registry.cloudogu.com"
LOCAL_TRIVY_CVE_LIST_CRITICAL=""
REMOTE_TRIVY_CVE_LIST_CRITICAL=""

CVE_SEVERITY="CRITICAL"

TRIVY_PATH="/tmp/trivy-dogu-cve-release"
TRIVY_RESULT_FILE="${TRIVY_PATH}/results.json"
TRIVY_CACHE_DIR="${TRIVY_PATH}/db"
TRIVY_DOCKER_CACHE_DIR=/tmp/db

USERNAME="${1}"
PASSWORD="${2}"

if [ -z "${USERNAME}" ]; then
  echo "username is unset"
  while [[ -z ${USERNAME} ]]; do
    read -r -p "type username for ${REGISTRY_URL}: " USERNAME
  done
fi
if [ -z "${PASSWORD}" ]; then
  echo "password is unset"
  while [[ -z ${PASSWORD} ]]; do
    read -r -s -p  "type password for ${REGISTRY_URL}: " PASSWORD
  done
fi

dockerLogin "${USERNAME}" "${PASSWORD}"

mkdir -p "${TRIVY_PATH}" # Cache will not be removed after release. rm requires root because the trivy container only runs with root.
pullRemoteImage
scanImage
parseTrivyJsonResult "${CVE_SEVERITY}" "${TRIVY_RESULT_FILE}"

buildLocalImage
scanImage
parseTrivyJsonResult "${CVE_SEVERITY}" "${TRIVY_RESULT_FILE}"

dockerLogout

CVE_IN_REMOTE_BUT_NOT_LOCAL=$(diffArrays "${REMOTE_TRIVY_CVE_LIST_CRITICAL}" "${LOCAL_TRIVY_CVE_LIST_CRITICAL}")
CVE_IN_LOCAL_BUT_NOT_REMOTE=$(diffArrays "${LOCAL_TRIVY_CVE_LIST_CRITICAL}" "${REMOTE_TRIVY_CVE_LIST_CRITICAL}")

if [[ -n "${CVE_IN_LOCAL_BUT_NOT_REMOTE}" ]]; then
  echo "Abort release. Added new vulnerabilities:"
  echo "${CVE_IN_LOCAL_BUT_NOT_REMOTE[@]}"
  exit 2
fi

if [[ -z "${CVE_IN_REMOTE_BUT_NOT_LOCAL}" ]]; then
  echo "Abort release. Fixed no new vulnerabilities"
  exit 3
fi

build/make/release.sh "dogu-cve-release" "${CVE_IN_REMOTE_BUT_NOT_LOCAL}"
