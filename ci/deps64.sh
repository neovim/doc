#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/neovim.sh
source ${BUILD_DIR}/ci/common/deps-repo.sh

clone_deps64() {
  clone_deps DEPS_${CI_OS^^}64
}

build_deps64() {
  echo "Building dependencies (64 bit)."
  build_deps DEPS_${CI_OS^^}64
}

commit_deps64() {
  commit_subtree DEPS_${CI_OS^^}64
}

clone_deps64
clone_neovim

build_deps64
commit_deps64
