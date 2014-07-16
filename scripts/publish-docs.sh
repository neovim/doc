#!/bin/bash -e

# Build documentation & reports for Neovim and
# pushes generated HTML to a "doc" Git repository.
# This script is based on http://philipuren.com/serendipity/index.php?/archives/21-Using-Travis-to-automatically-publish-documentation.html

# Set BUILD_DIR default value for local test runs
BUILD_DIR=${TRAVIS_BUILD_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"}
NEOVIM_DIR=${BUILD_DIR}/build/neovim
NEOVIM_REPO=neovim/neovim
NEOVIM_BRANCH=master
DOC_DIR=${BUILD_DIR}/build/doc
DOC_REPO=neovim/doc
DOC_BRANCH=gh-pages
MAKE_CMD="make -j2"
REPORTS=(doxygen clang-report translation-report)

# Helper function for report generation
# ${1}:   Report title
# ${2}:   Report body
# ${3}:   Path to HTML output file
# Output: None
generate_report() {
  report_title="${1}" \
  report_body="${2}" \
  report_date=$(date -u) \
  report_commit="${NEOVIM_COMMIT}" \
  report_short_commit="${NEOVIM_COMMIT:0:7}" \
  report_repo="${NEOVIM_REPO}" \
  report_header=$(<${BUILD_DIR}/templates/${REPORT}/head.html) \
  envsubst < "${BUILD_DIR}/templates/report.sh.html" > "${3}"
}

# Clone code & doc repos
git clone --branch ${NEOVIM_BRANCH} --depth 1 https://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
git clone --branch ${DOC_BRANCH} --depth 1 https://github.com/${DOC_REPO} ${DOC_DIR}
NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)

# Generate documentation & reports
for REPORT in ${REPORTS[@]}; do
  echo "Generating ${REPORT//-/ }."
  source ${BUILD_DIR}/scripts/generate-${REPORT}.sh
  generate_${REPORT//-/_}
done

# Exit early if not built on Travis to simplify
# local test runs of this script
if [[ -z "${GH_TOKEN}" ]]; then
  echo "GH_TOKEN not set, exiting..."
  exit 1
fi

# Set up Git credentials
git config --global user.name "${GIT_NAME}"
git config --global user.email ${GIT_EMAIL}

# Commit the updated docs
cd ${DOC_DIR}
git add --all .
git commit --amend --reset-author -m "Documentation: Automatic update."
git push --force https://${GH_TOKEN}@github.com/${DOC_REPO} ${DOC_BRANCH}
