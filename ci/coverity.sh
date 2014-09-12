#!/bin/bash -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/neovim.sh

COVERITY_BRANCH=${COVERITY_BRANCH:-master}

trigger_coverity() {
  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

  cd ${NEOVIM_DIR}
  wget -q -O - https://scan.coverity.com/scripts/travisci_build_coverity_scan.sh |
    TRAVIS_BRANCH="${NEOVIM_BRANCH}" \
    COVERITY_SCAN_PROJECT_NAME="${NEOVIM_REPO}" \
    COVERITY_SCAN_NOTIFICATION_EMAIL="coverity@aktau.be" \
    COVERITY_SCAN_BRANCH_PATTERN="${COVERITY_BRANCH}" \
    COVERITY_SCAN_BUILD_COMMAND_PREPEND="${MAKE_CMD} deps" \
    COVERITY_SCAN_BUILD_COMMAND="${MAKE_CMD} nvim" \
    bash || echo "Running coverity script failed, ignoring."
}

clone_neovim
trigger_coverity
