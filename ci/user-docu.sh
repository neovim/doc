#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh

generate_user_docu() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable MAKE_CMD "${BASH_SOURCE[0]}" ${LINENO}

  # Generate CMake files
  cd ${NEOVIM_DIR}
  make cmake
  # Build Neovim (which also creates help tags).
  cd build
  ${MAKE_CMD}

  # Generate HTML from :help docs.
  cd ..
  VIMRUNTIME=runtime/ ./build/bin/nvim -V1 -es --clean \
    +"lua require('scripts.gen_help_html').gen('./build/runtime/doc/', '${DOC_DIR}/user', nil, '${NEOVIM_COMMIT}')" +0cq
}

DOC_SUBTREE="/user/"
generate_user_docu
