#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Release functions for v3 dogus, sourced by release_functions.sh.

# Prefix of the v3 tag (chart/v<chart version>)
# shellcheck disable=SC2034 # used in release.sh
V3_TAG_PREFIX="chart"

# get_release_kind prints how the project is released:
# - v2: without cldk.yaml (or no dogu) as before,
# - double: as v2 and v3 dogu (Doppel-Release), always for a dogu-cve-release,
# - v3-only: only the chart of the v3 dogu, always for a dogu without dogu.json, otherwise on request.
get_release_kind() {
  local TYPE="${1}"

  if [[ "${TYPE}" != "dogu" && "${TYPE}" != "dogu-cve-release" ]] || ! is_v3_dogu; then
    echo "v2"
  elif [[ ! -f "dogu.json" ]]; then
    echo "v3-only"
  elif [[ "${TYPE}" == "dogu-cve-release" ]]; then
    echo "double"
  elif [[ "$(ask_yes_or_no "Release the v2 dogu as well? Otherwise only the chart of the v3 dogu is released.")" == "y" ]]; then
    echo "double"
  else
    echo "v3-only"
  fi
}

# is_v3_dogu succeeds if the project is (also) released as v3 dogu, which is marked by a cldk.yaml.
is_v3_dogu() {
  [[ -f "cldk.yaml" ]]
}

# yq runs the yq installed with "make install-yq" (.bin/yq) if present, otherwise the yq from the PATH.
yq() {
  if [[ -x ".bin/yq" ]]; then
    .bin/yq "$@"
  else
    command yq "$@"
  fi
}

# get_chart_file prints the path of the Chart.yaml of the v3 dogu, in the directory "chart" of the cldk.yaml (default k8s/helm).
get_chart_file() {
  echo "$(yq '.chart // "k8s/helm"' cldk.yaml)/Chart.yaml"
}

# get_current_chart_version prints the version from the Chart.yaml of the v3 dogu.
get_current_chart_version() {
  yq '.version' "$(get_chart_file)"
}

# get_dogu_name_by_chart prints the name from the Chart.yaml of the v3 dogu, which is the simple dogu name and the name
# of the dogu image in the cldk.yaml.
get_dogu_name_by_chart() {
  yq '.name' "$(get_chart_file)"
}

# check_dogu_image_in_cldk_yaml fails if the cldk.yaml has no image named like the dogu.
check_dogu_image_in_cldk_yaml() {
  local DOGU_NAME
  DOGU_NAME="$(get_dogu_name_by_chart)"
  if ! DOGU_NAME="${DOGU_NAME}" yq -e '.images | has(strenv(DOGU_NAME))' cldk.yaml >/dev/null 2>&1; then
    echo "ERROR: The cldk.yaml contains no image '${DOGU_NAME}' below 'images'."
    return 1
  fi
}

# validate_v3_dogu checks the v3 prerequisites before the release branch is started: yq v4 and the Chart.yaml.
validate_v3_dogu() {
  if ! yq --version 2>/dev/null | grep -qE 'mikefarah/yq.* v?4\.'; then
    echo "ERROR: The release of v3 dogus needs yq v4 from https://github.com/mikefarah/yq."
    echo "Install it with 'make install-yq' (needs Go) or put it into the PATH."
    return 1
  fi

  local CHART_FILE
  CHART_FILE="$(get_chart_file)"
  if [[ ! -f "${CHART_FILE}" ]]; then
    echo "ERROR: The v3 dogu has no ${CHART_FILE}. Please set 'chart' in the cldk.yaml."
    return 1
  fi
}

read_new_chart_version() {
  local CURRENT_CHART_VERSION="${1}"
  local NEW_CHART_VERSION
  read -r -p "Current chart version of the v3 dogu is ${CURRENT_CHART_VERSION}. Please provide the new chart version: " NEW_CHART_VERSION
  echo "${NEW_CHART_VERSION}"
}

# validate_new_chart_version fails if the new chart version is no MAJOR.MINOR.PATCH version or not greater than the current chart version.
validate_new_chart_version() {
  local NEW_CHART_VERSION="${1}"
  local CURRENT_CHART_VERSION="${2}"
  local CHART_VERSION_REGEX='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

  if [[ ! "${CURRENT_CHART_VERSION}" =~ ${CHART_VERSION_REGEX} ]]; then
    echo "ERROR: The current chart version '${CURRENT_CHART_VERSION}' in the Chart.yaml is no valid chart version (MAJOR.MINOR.PATCH)."
    return 1
  fi

  if [[ ! "${NEW_CHART_VERSION}" =~ ${CHART_VERSION_REGEX} ]]; then
    echo "ERROR: The new chart version '${NEW_CHART_VERSION}' is no valid chart version (MAJOR.MINOR.PATCH). Do not enter a leading v."
    return 1
  fi

  # "sort -V" sorts numerically per version part (0.9.1 < 0.10.0), which matches SemVer for MAJOR.MINOR.PATCH versions.
  # The new version must be the last one after sorting and differ from the current one, so equal versions are rejected.
  local GREATEST_VERSION
  GREATEST_VERSION="$(printf '%s\n%s\n' "${CURRENT_CHART_VERSION}" "${NEW_CHART_VERSION}" | sort -V | tail -n 1)"
  if [[ "${NEW_CHART_VERSION}" == "${CURRENT_CHART_VERSION}" || "${GREATEST_VERSION}" != "${NEW_CHART_VERSION}" ]]; then
    echo "ERROR: The new chart version ${NEW_CHART_VERSION} must be greater than the current chart version ${CURRENT_CHART_VERSION}."
    return 1
  fi
}

# get_app_version_by_v2_dogu_version prints the app version part of a v2 dogu version (3.96.4-4 -> 3.96.4).
get_app_version_by_v2_dogu_version() {
  echo "${1%-*}"
}

# update_v3_versions sets the chart version and the app version in the Chart.yaml and the new v2 dogu version as tag of the dogu image in the cldk.yaml.
update_v3_versions() {
  local NEW_RELEASE_VERSION="${1}"
  local NEW_CHART_VERSION="${2}"
  local CHART_FILE
  CHART_FILE="$(get_chart_file)"
  check_dogu_image_in_cldk_yaml || return 1

  echo "Updating version and appVersion in ${CHART_FILE}..."
  CHART_VERSION="${NEW_CHART_VERSION}" APP_VERSION="$(get_app_version_by_v2_dogu_version "${NEW_RELEASE_VERSION}")" \
    yq -i '.version = strenv(CHART_VERSION) | .appVersion = strenv(APP_VERSION) | .appVersion style="double"' "${CHART_FILE}"

  local DOGU_NAME
  DOGU_NAME="$(get_dogu_name_by_chart)"
  echo "Updating tag of image ${DOGU_NAME} in cldk.yaml..."
  DOGU_NAME="${DOGU_NAME}" IMAGE_TAG="${NEW_RELEASE_VERSION}" \
    yq -i '.images[strenv(DOGU_NAME)].tag = strenv(IMAGE_TAG) | .images[strenv(DOGU_NAME)] style=""' cldk.yaml
}

# update_chart_version sets the chart version in the Chart.yaml of a v3-only release and commits it after verification.
update_chart_version() {
  local NEW_CHART_VERSION="${1}"
  local CHART_FILE
  CHART_FILE="$(get_chart_file)"

  echo "Updating version in ${CHART_FILE}..."
  CHART_VERSION="${NEW_CHART_VERSION}" yq -i '.version = strenv(CHART_VERSION)' "${CHART_FILE}"

  wait_for_ok "Please make sure that the chart version has been updated correctly now (e.g. via \"git diff\")."
  git add "${CHART_FILE}"
  git commit -m "Bump chart version"
}
