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
  # release_functions.sh works on the current directory, so every test gets its own dogu project.
  # Chart.yaml and cldk.yaml of a nexus-like dogu project and the expected files after a release
  FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures/release_v3"
  PROJECT_DIR="${BATS_TEST_TMPDIR}/project"
  mkdir -p "${PROJECT_DIR}"
  cd "${PROJECT_DIR}"
}

teardown() {
  unset MAKE_DIR
  unset WORKDIR
}

# init_dogu_repo makes the current directory a git repository on branch develop with the files of the current directory,
# so that release.sh can start a dry run release.
init_dogu_repo() {
  mkdir -p build
  ln -s "${MAKE_DIR}" build/make
  printf '# Changelog\n\n## [Unreleased]\n### Changed\n- Something\n' > CHANGELOG.md
  export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
  git init --quiet --initial-branch=develop
  echo "build/" > .gitignore
  git add .
  git commit --quiet -m "initial"
}

@test "is_v3_dogu should succeed only if a cldk.yaml exists" {
  source "${MAKE_DIR}/release_functions.sh"

  run is_v3_dogu
  assert_failure 1

  touch cldk.yaml
  run is_v3_dogu
  assert_success
}

@test "validate_new_chart_version should accept a greater version" {
  source "${MAKE_DIR}/release_functions.sh"

  run validate_new_chart_version "0.10.0" "0.9.1"

  assert_success
}

@test "validate_new_chart_version should reject smaller, equal and invalid versions" {
  source "${MAKE_DIR}/release_functions.sh"

  for INVALID_VERSION in "0.9.0" "0.9.1" "v1.0.0" "1.0.0-rc.1" "1.0" ""; do
    run validate_new_chart_version "${INVALID_VERSION}" "0.9.1"

    assert_failure 1
  done
}

@test "update_v3_versions should set chart version, app version and the tag of the dogu image" {
  source "${MAKE_DIR}/release_functions.sh"
  cp -r "${FIXTURES_DIR}/project/." .

  run update_v3_versions "3.97.0-2" "0.1.0"

  assert_success
  assert_files_equal k8s/helm/Chart.yaml "${FIXTURES_DIR}/expected/Chart.yaml"
  assert_files_equal cldk.yaml "${FIXTURES_DIR}/expected/cldk.yaml"
}

@test "check_dogu_image_in_cldk_yaml should fail if the cldk.yaml contains no image named like the dogu" {
  source "${MAKE_DIR}/release_functions.sh"
  cp -r "${FIXTURES_DIR}/project/." .
  sed -i 's/^  nexus:/  other:/' cldk.yaml

  run check_dogu_image_in_cldk_yaml

  assert_failure 1
  assert_output --partial "no image 'nexus'"
}

@test "get_release_kind should release v2 without cldk.yaml, v3-only without dogu.json and ask a dogu with both" {
  source "${MAKE_DIR}/release_functions.sh"

  assert_equal "$(get_release_kind dogu)" "v2"
  touch cldk.yaml
  assert_equal "$(get_release_kind go-tool)" "v2"
  assert_equal "$(get_release_kind dogu)" "v3-only"
  touch dogu.json
  assert_equal "$(get_release_kind dogu-cve-release)" "double"
  assert_equal "$(get_release_kind dogu <<< "y")" "double"
  assert_equal "$(get_release_kind dogu <<< "n")" "v3-only"
}

@test "update_chart_version should only set the chart version and commit it" {
  source "${MAKE_DIR}/release_functions.sh"
  cp -r "${FIXTURES_DIR}/project/." .
  init_dogu_repo

  run update_chart_version "0.1.0" <<< "ok"

  assert_success
  assert_equal "$(git log -1 --format=%s)" "Bump chart version"
  assert_files_equal k8s/helm/Chart.yaml "${FIXTURES_DIR}/expected_v3_only/Chart.yaml"
  assert_files_equal cldk.yaml "${FIXTURES_DIR}/project/cldk.yaml"
}

@test "release.sh dry run should release only the chart of a dogu without dogu.json" {
  cp -r "${FIXTURES_DIR}/project/." .
  init_dogu_repo

  run bash -c "printf '0.1.0\nok\nok\n' | build/make/release.sh dogu '' true"

  assert_success
  assert_output --partial "Switched to a new branch 'dryrun/chart/v0.1.0'"
  assert_output --partial "+version: 0.1.0"
  assert_output --partial "+## [chart/v0.1.0] - "
  refute_output --partial "Chart-Version:"
  refute_output --partial "+appVersion"
  refute_output --partial "cldk.yaml"
  assert_equal "$(git branch --show-current)" "develop"
}

@test "release.sh dry run should release only the chart of a double release dogu if the v2 dogu is not released" {
  cp -r "${FIXTURES_DIR}/project/." .
  echo '{"Name": "official/nexus", "Version": "3.96.4-1"}' > dogu.json
  init_dogu_repo

  run bash -c "printf 'n\n0.1.0\nok\nok\n' | build/make/release.sh dogu '' true"

  assert_success
  assert_output --partial "Switched to a new branch 'dryrun/chart/v0.1.0'"
  assert_output --partial "+version: 0.1.0"
  assert_output --partial "+## [chart/v0.1.0] - "
  refute_output --partial "dogu.json"
  refute_output --partial "cldk.yaml"
  assert_equal "$(git branch --show-current)" "develop"
}

@test "release.sh dry run should release a double release dogu as v2 and v3 dogu" {
  cp -r "${FIXTURES_DIR}/project/." .
  echo '{"Name": "official/nexus", "Version": "3.96.4-1"}' > dogu.json
  init_dogu_repo

  run bash -c "printf 'y\n3.97.0-2\n0.1.0\nok\nok\n' | build/make/release.sh dogu '' true"

  assert_success
  assert_output --partial "Switched to a new branch 'dryrun/v3.97.0-2'"
  assert_output --partial '+  "Version": "3.97.0-2"'
  assert_output --partial "+version: 0.1.0"
  assert_output --partial '+appVersion: "3.97.0"'
  assert_output --partial "+    tag: 3.97.0-2"
  assert_output --partial "+## [v3.97.0-2] - "
  assert_output --partial "+Chart-Version: 0.1.0"
  assert_equal "$(git branch --show-current)" "develop"
}
