#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh

generate_user_docu() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

  cd ${NEOVIM_DIR}
  make

  # Generate HTML from :help docs.
  VIMRUNTIME=runtime/ ./build/bin/nvim -V1 -es --clean \
    +"lua require('src.gen.gen_help_html').gen('./build/runtime/doc/', '${DOC_DIR}/user', nil, '${NEOVIM_COMMIT}')" +0cq
}

DOC_SUBTREE="/user/"
generate_user_docu
