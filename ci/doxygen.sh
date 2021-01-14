#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh

generate_doxygen() {
  cd ${NEOVIM_DIR}

  mkdir -p build
  doxygen src/Doxyfile

  rm -rf ${DOC_DIR}/dev
  mv build/doxygen/html ${DOC_DIR}/dev
}

DOC_SUBTREE="/dev/"
generate_doxygen
