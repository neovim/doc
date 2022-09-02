#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh
source ${BUILD_DIR}/ci/common/html.sh

generate_user_docu() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable MAKE_CMD "${BASH_SOURCE[0]}" ${LINENO}

  # Generate CMake files
  cd ${NEOVIM_DIR}
  make cmake

  # Build user manual HTML
  cd build
  echo "CWD: $(pwd)"

  # Legacy HTML (will be removed)
  ${MAKE_CMD} doc_html

  # Copy to doc repository
  rm -rf ${DOC_DIR}/user
  mkdir -p ${DOC_DIR}/user
  cp runtime/doc/*.html ${DOC_DIR}/user

  # Generate HTML from :help docs.
  (
    cd ..
    VIMRUNTIME=runtime/ ./build/bin/nvim -V1 -es --clean +"lua require('scripts.gen_help_html').gen('./build/runtime/doc/', '${DOC_DIR}/user2', nil)" +0cq
  )

  # Modify HTML to match Neovim's layout
  modify_user_docu
}

# Helper function to modify user documentation HTML
# to use Neovim layout
modify_user_docu() {
  for file in ${DOC_DIR}/user/*.html; do
    local title="$(extract_title ${file})"
    local body="$(echo "$(extract_body ${file})" | sed -e 's/color="purple"/color="#3A6F2B"/Ig')"
    generate_report "${title}" "${body}" "${file}"
  done
}

DOC_SUBTREE="/user/"
generate_user_docu
