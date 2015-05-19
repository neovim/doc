#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/neovim.sh"
source "${BUILD_DIR}/ci/common/deps-repo.sh"

DEPS_SRC_BUILD_DIR=${DEPS_SRC_BUILD_DIR:-${BUILD_DIR}/build/deps-src}

clone_deps-src() {
  clone_deps DEPS_SRC
}

extract_sources() {
  rm -rf "${DEPS_SRC_BUILD_DIR}"
  mkdir -p "${DEPS_SRC_BUILD_DIR}"

  echo "Building dependencies."
  cd "${DEPS_SRC_BUILD_DIR}"
  # Disable dependencies only required for tests
  cmake -DUSE_BUNDLED_BUSTED=OFF "${NEOVIM_DIR}/third-party/"
  make

  echo "Extracting sources."
  cd "${DEPS_SRC_BUILD_DIR}/build/src"
  rm -rf ./*-{stamp,build}
  while read dir; do
    cd "${DEPS_SRC_BUILD_DIR}/build/src/${dir}"
    echo "Cleaning ${dir}."
    rm -rf autom4te.cache
    make clean || true
    make distclean || true
  done <<< "$(find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n')"

  # Move into cloned repo's path for committing.
  rm -rf "${DEPS_SRC_DIR%/}/${DEPS_SRC_SUBTREE%/}"/*
  mv "${DEPS_SRC_BUILD_DIR}/build/src"/* "${DEPS_SRC_DIR%/}/${DEPS_SRC_SUBTREE}"
}

commit_deps-src() {
  commit_subtree DEPS_SRC
}

clone_deps-src
clone_neovim

extract_sources
commit_deps-src
