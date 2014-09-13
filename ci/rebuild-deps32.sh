#!/bin/bash -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/deps-repo.sh
source ${BUILD_DIR}/ci/common/neovim.sh

clone_deps32() {
  clone_deps DEPS32
}

build_deps32() {
  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}
  echo "Building dependencies (32 bit)."
  build_deps DEPS32 "-DCMAKE_TOOLCHAIN_FILE=${NEOVIM_DIR}/cmake/i386-linux-gnu.toolchain.cmake"
}

commit_deps32() {
  commit_subtree DEPS32
}

is_ci_build && {
  install_gcc_multilib
}

clone_deps32
clone_neovim

build_deps32
commit_deps32
