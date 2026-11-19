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

@test "validate_v3_dogu should fail if the cldk.yaml contains no image named like the dogu" {
  source "${MAKE_DIR}/release_functions.sh"
  cp -r "${FIXTURES_DIR}/project/." .
  sed -i 's/^  nexus:/  other:/' cldk.yaml

  run validate_v3_dogu

  assert_failure 1
  assert_output --partial "no image 'nexus'"
}
