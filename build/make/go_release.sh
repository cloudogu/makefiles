#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source "$(pwd)/build/make/release_util.sh"

echo "=====Starting Release process====="

# Makefile will always exist containing the version. Get version from makefile.
CURRENT_TOOL_VERSION=$(grep '^VERSION=[0-9a-Z.]*$' Makefile | sed s/VERSION=//g)

# Enter the target version
read -r -p "Current Version is v${CURRENT_TOOL_VERSION}. Please provide the new version: v" NEW_RELEASE_VERSION

validate_new_version "${NEW_RELEASE_VERSION}"
start_git_flow_release "${NEW_RELEASE_VERSION}"
update_versions "${NEW_RELEASE_VERSION}"
update_changelog "${NEW_RELEASE_VERSION}"
show_diff
finish_release_and_push "${CURRENT_TOOL_VERSION}" "${NEW_RELEASE_VERSION}"