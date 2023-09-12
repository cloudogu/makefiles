#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source "$(pwd)/build/make/release_functions.sh"

USERNAME="${1}"
PASSWORD="${2}"

#getRemoteAndLocalCVEList "${USERNAME}" "${PASSWORD}"

### Testdata
#LOCAL_TRIVY_CVE_LIST_MEDIUM="CVE-1 CVE-2 CVE-2 CVE-3 CVE-4"
#REMOTE_TRIVY_CVE_LIST_MEDIUM="CVE-1 CVE-2 CVE-3 CVE-4"

function intersectArrays {
  local I=("$1")
  local J=("$2")
  local RESULT=()

  for i in ${I}; do
    found=0
    for j in ${J}; do
      [[ "${j}" == "${i}" ]] && { found=1; break; }
    done

    [[ $found == 0 ]] && RESULT+=("$i")
  done

  echo "${RESULT[@]}"
}

CVE_IN_REMOTE_BUT_NOT_LOCAL=$(intersectArrays "${REMOTE_TRIVY_CVE_LIST_MEDIUM}" "${LOCAL_TRIVY_CVE_LIST_MEDIUM}")
CVE_IN_LOCAL_BUT_NOT_REMOTE=$(intersectArrays "${LOCAL_TRIVY_CVE_LIST_MEDIUM}" "${REMOTE_TRIVY_CVE_LIST_MEDIUM}")

if [[ -n "${CVE_IN_LOCAL_BUT_NOT_REMOTE}" ]]; then
  echo "Added new vulnerabilities:"
  echo "${CVE_IN_LOCAL_BUT_NOT_REMOTE[@]}"
  exit 2
fi

if [[ -z "${CVE_IN_REMOTE_BUT_NOT_LOCAL}" ]]; then
  echo "Fixed no new vulnerabilities"
  exit 3
fi


echo "=====Starting Release process====="

if [ "${TYPE}" == "dogu" ];then
  CURRENT_TOOL_VERSION=$(get_current_version_by_dogu_json)
else
  CURRENT_TOOL_VERSION=$(get_current_version_by_makefile)
fi

NEW_RELEASE_VERSION="$(read_new_version)"

validate_new_version "${NEW_RELEASE_VERSION}"
start_git_flow_release "${NEW_RELEASE_VERSION}"
update_versions "${NEW_RELEASE_VERSION}"
update_changelog "${NEW_RELEASE_VERSION}"
show_diff
#finish_release_and_push "${CURRENT_TOOL_VERSION}" "${NEW_RELEASE_VERSION}"

echo "=====Finished Release process====="
