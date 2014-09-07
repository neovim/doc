#!/bin/bash -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/documentation.sh

generate_doxygen() {
  cd ${NEOVIM_DIR}

  mkdir -p build
  doxygen

  rm -rf ${DOC_DIR}/dev
  mv build/doxygen/html ${DOC_DIR}/dev
}

(
  DOC_SUBTREE="/dev/"
  install_dependencies
  clone_doc
  clone_neovim
  generate_doxygen
  commit_doc
)
