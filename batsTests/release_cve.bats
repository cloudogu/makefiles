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
  export PATH="${PATH}:${BATS_TMPDIR}"
}

teardown() {
  unset MAKE_DIR
  unset WORKDIR
}

@test "source script with bash should return exit code 0" {
  run source "${MAKE_DIR}/release_cve.sh"

  assert_success
}

