#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/neovim.sh"

COVERITY_BRANCH=${COVERITY_BRANCH:-master}
COVERITY_LOG_FILE="${BUILD_DIR}/build/neovim/cov-int/scm_log.txt"

# Check day of week to run Coverity only on Monday, Wednesday, Friday, and Saturday.
is_date_ok() {
  local current_weekday=$(date -u +'%u')

  if [[ ${current_weekday} == 2 || ${current_weekday} == 4 || ${current_weekday} == 7 ]]; then
    echo "Today is $(date -u +'%A'), not triggering Coverity."
    echo "Next Coverity build is scheduled for $(date -u -d 'tomorrow' +'%A')."
    return 1
  fi
}

trigger_coverity() {
  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

  cd "${NEOVIM_DIR}"
  wget -q -O - https://scan.coverity.com/scripts/travisci_build_coverity_scan.sh |
    TRAVIS_BRANCH="${NEOVIM_BRANCH}" \
    COVERITY_SCAN_PROJECT_NAME="${NEOVIM_REPO}" \
    COVERITY_SCAN_NOTIFICATION_EMAIL="coverity@aktau.be" \
    COVERITY_SCAN_BRANCH_PATTERN="${COVERITY_BRANCH}" \
    COVERITY_SCAN_BUILD_COMMAND_PREPEND="${MAKE_CMD} deps" \
    COVERITY_SCAN_BUILD_COMMAND="${MAKE_CMD} nvim" \
    bash

  if [[ -f "${COVERITY_LOG_FILE}" ]]; then
    echo "Contents of ${COVERITY_LOG_FILE}:"
    cat "${COVERITY_LOG_FILE}"
  fi
}

is_date_ok && {
  clone_neovim
  trigger_coverity
}

exit 0
