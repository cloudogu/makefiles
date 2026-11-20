#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Extension points in release.sh:
#
# A custom release argument file will be sourced if found. The custom release arg file may implement one or more bash
# functions which either release.sh or release_functions.sh define. If such a custom release function is found the
# release script must define the argument list which the custom release function will receive during the release.

sourceCustomReleaseArgs() {
  RELEASE_ARGS_FILE="${1}"

  if [[ -f "${RELEASE_ARGS_FILE}" ]]; then
    echo "Using custom release args file ${RELEASE_ARGS_FILE}"

    local sourceCustomReleaseExitCode=0
    # shellcheck disable=SC1090
    source "${RELEASE_ARGS_FILE}" || sourceCustomReleaseExitCode=$?
    if [[ ${sourceCustomReleaseExitCode} -ne 0 ]]; then
      echo "Error while sourcing custom release arg file ${sourceCustomReleaseExitCode}. Exiting."
      exit 9
    fi
  fi
}

PROJECT_DIR="$(pwd)"
RELEASE_ARGS_FILE="${PROJECT_DIR}/release_args.sh"

sourceCustomReleaseArgs "${RELEASE_ARGS_FILE}"

# shellcheck disable=SC1090
source "$(pwd)/build/make/release_functions.sh"

TYPE="${1}"
FIXED_CVE_LIST="${2:-""}"
DRY_RUN="${3:-""}"

# start_release starts the release branch release/<release name>, or dryrun/<release name> for a dry run.
# A v3-only release passes an empty NEW_RELEASE_VERSION.
start_release() {
  local NEW_RELEASE_VERSION="${1}"
  local RELEASE_NAME="${2}"

  if [[ -n "${DRY_RUN}" ]]; then
    start_dry_run_release "${NEW_RELEASE_VERSION}" "${RELEASE_NAME}"
  else
    start_git_flow_release "${NEW_RELEASE_VERSION}" "${BASE_VERSION}" "${RELEASE_NAME}"
  fi
}

# end_release pushes the release branch, or deletes it for a dry run.
end_release() {
  local CURRENT_VERSION="${1}"
  local NEW_VERSION="${2}"
  local RELEASE_NAME="${3}"

  if [[ -n "${DRY_RUN}" ]]; then
    abort_dry_run_release "${NEW_VERSION}" "${BASE_VERSION}" "${RELEASE_NAME}"
  else
    finish_release_and_push "${CURRENT_VERSION}" "${NEW_VERSION}" "${BASE_VERSION}" "${RELEASE_NAME}"
  fi
}

# read_v2_versions sets CURRENT_TOOL_VERSION and asks for NEW_RELEASE_VERSION.
read_v2_versions() {
  if [[ "${TYPE}" == "dogu" || "${TYPE}" == "dogu-cve-release" ]]; then
    CURRENT_TOOL_VERSION=$(get_current_version_by_dogu_json)
  else
    CURRENT_TOOL_VERSION=$(get_current_version_by_makefile)
  fi
  NEW_RELEASE_VERSION="$(read_new_version)"
  validate_new_version "${NEW_RELEASE_VERSION}"
}

# read_chart_versions checks the v3 dogu, sets CURRENT_CHART_VERSION and asks for NEW_CHART_VERSION.
read_chart_versions() {
  validate_v3_dogu || exit 1
  CURRENT_CHART_VERSION="$(get_current_chart_version)"
  NEW_CHART_VERSION="$(read_new_chart_version "${CURRENT_CHART_VERSION}")"
  validate_new_chart_version "${NEW_CHART_VERSION}" "${CURRENT_CHART_VERSION}" || exit 1
}

release_v2() {
  read_v2_versions
  local RELEASE_NAME="v${NEW_RELEASE_VERSION}"

  start_release "${NEW_RELEASE_VERSION}" "${RELEASE_NAME}"
  update_versions "${NEW_RELEASE_VERSION}"
  update_changelog "${NEW_RELEASE_VERSION}" "${FIXED_CVE_LIST}"
  update_releasenotes "${NEW_RELEASE_VERSION}"
  show_diff
  end_release "${CURRENT_TOOL_VERSION}" "${NEW_RELEASE_VERSION}" "${RELEASE_NAME}"
}

# release_double releases the dogu as v2 and v3 dogu: like release_v2 plus the chart version, the app version and the
# tag of the dogu image for the v3 dogu.
release_double() {
  read_v2_versions
  read_chart_versions
  check_dogu_image_in_cldk_yaml || exit 1
  local RELEASE_NAME="v${NEW_RELEASE_VERSION}"

  start_release "${NEW_RELEASE_VERSION}" "${RELEASE_NAME}"
  update_versions "${NEW_RELEASE_VERSION}" "${NEW_CHART_VERSION}"
  update_changelog "${NEW_RELEASE_VERSION}" "${FIXED_CVE_LIST}" "${NEW_CHART_VERSION}"
  update_releasenotes "${NEW_RELEASE_VERSION}"
  show_diff
  end_release "${CURRENT_TOOL_VERSION}" "${NEW_RELEASE_VERSION}" "${RELEASE_NAME}"
}

# release_v3_only releases only the chart of the v3 dogu: only the chart version in the Chart.yaml changes.
release_v3_only() {
  read_chart_versions
  local RELEASE_NAME="${V3_TAG_PREFIX}/v${NEW_CHART_VERSION}"

  start_release "" "${RELEASE_NAME}"
  update_chart_version "${NEW_CHART_VERSION}"
  update_changelog "" "" "" "${RELEASE_NAME}"
  update_releasenotes "" "${RELEASE_NAME}"
  show_diff
  end_release "${CURRENT_CHART_VERSION}" "${NEW_CHART_VERSION}" "${RELEASE_NAME}"
}

echo "=====Starting Release process====="

BASE_VERSION=$(get_base_version_by_makefile)

RELEASE_KIND="$(get_release_kind "${TYPE}")"
case "${RELEASE_KIND}" in
  v2) release_v2 ;;
  double) release_double ;;
  v3-only) release_v3_only ;;
esac

echo "=====Finished Release process====="
