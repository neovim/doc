#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh
source ${BUILD_DIR}/ci/common/neovim.sh
source ${BUILD_DIR}/ci/common/html.sh

generate_user_docu() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable MAKE_CMD "${BASH_SOURCE[0]}" ${LINENO}

  cd ${NEOVIM_DIR}/runtime/doc
  ${MAKE_CMD} html

  # Copy to doc repository
  rm -rf ${DOC_DIR}/user
  mkdir -p ${DOC_DIR}/user
  cp -r *.html ${DOC_DIR}/user

  # Modify HTML to match Neovim's layout
  modify_user_docu
}

# Helper function to modify user documentation HTML
# to use Neovim layout
modify_user_docu() {
  for file in ${DOC_DIR}/user/*.html; do
    local title="$(extract_title ${file})"
    local body="$(echo "$(extract_body ${file})" | sed -e 's/color="purple"/color="#54A23D"/Ig')"
    generate_report "${title}" "${body}" "${file}"
  done
}

DOC_SUBTREE="/user/"
clone_doc
clone_neovim
generate_user_docu
commit_doc
