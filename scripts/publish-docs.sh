#!/bin/bash -e

# Build documentation & reports for Neovim and
# pushes generated HTML to a "doc" Git repository.
# This script is based on http://philipuren.com/serendipity/index.php?/archives/21-Using-Travis-to-automatically-publish-documentation.html

# Set BUILD_DIR to build/ for local runs
BUILD_DIR=${TRAVIS_BUILD_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"}/build
NEOVIM_DIR=${BUILD_DIR}/neovim
NEOVIM_REPO=neovim/neovim
NEOVIM_BRANCH=master
DOC_DIR=${BUILD_DIR}/doc
DOC_REPO=neovim/doc
DOC_BRANCH=gh-pages
MAKE_CMD="make -j2"

generate_doxygen() {
  cd ${NEOVIM_DIR}

  mkdir -p build
  doxygen

  rm -rf ${DOC_DIR}/dev
  mv build/doxygen/html ${DOC_DIR}/dev
}

generate_clang_report() {
  cd ${NEOVIM_DIR}

  ${MAKE_CMD} deps
  mkdir -p build/clang-report
  scan-build \
    --use-analyzer=$(which clang) \
    --html-title="Neovim Static Analysis Report" \
    -o build/clang-report \
    ${MAKE_CMD}

  rm -rf ${DOC_DIR}/build-reports/clang
  mkdir -p ${DOC_DIR}/build-reports/clang
  cp -r build/clang-report/*/* ${DOC_DIR}/build-reports/clang
}

# Clone code & doc repos
git clone --depth 1 https://github.com/${NEOVIM_REPO} ${NEOVIM_DIR} --branch ${NEOVIM_BRANCH}
git clone https://github.com/${DOC_REPO} ${DOC_DIR} --branch ${DOC_BRANCH}

# Generate documentation & reports
generate_doxygen
generate_clang_report

# Exit early if not built on Travis to simplify
# local test runs of this script
if [ -z "${GH_TOKEN}" ]
then
  echo "GH_TOKEN not set, exiting..."
  exit 1
fi

# Set up Git credentials
git config --global user.name "${GIT_NAME}"
git config --global user.email ${GIT_EMAIL}

# Commit the updated docs
cd ${DOC_DIR}
git add --all .
git commit --amend -m "Documentation: Automatic update."
git push --force https://${GH_TOKEN}@github.com/${DOC_REPO} ${DOC_BRANCH}
