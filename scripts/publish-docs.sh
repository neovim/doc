#!/bin/bash -e

# Build documentation & reports for Neovim and
# pushes generated HTML to a "doc" Git repository.
# This script is based on http://philipuren.com/serendipity/index.php?/archives/21-Using-Travis-to-automatically-publish-documentation.html

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
  LOCAL_BUILD=true
  BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
else
  LOCAL_BUILD=false
  BUILD_DIR=${TRAVIS_BUILD_DIR}
fi

NEOVIM_DIR=${BUILD_DIR}/build/neovim
NEOVIM_REPO=neovim/neovim
NEOVIM_BRANCH=master
DOC_DIR=${BUILD_DIR}/build/doc
DOC_REPO=neovim/doc
DOC_BRANCH=gh-pages
MAKE_CMD="make -j2"

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
  report_header=$([ -f ${BUILD_DIR}/templates/${REPORT}/head.html ] && cat ${BUILD_DIR}/templates/${REPORT}/head.html) \
  envsubst < "${BUILD_DIR}/templates/report.sh.html" > "${3}"
}

# Install dependencies
if [[ ${LOCAL_BUILD} == false ]]; then
  source ${BUILD_DIR}/scripts/install-deps.sh
  install_deps
else
  echo "Local build, not installing dependencies."
fi

# Clone code repo
git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)

# Include report functions
source ${BUILD_DIR}/scripts/generate-${REPORT}.sh

# Clone subdirectory according to report type
(
  git init ${DOC_DIR}
  cd ${DOC_DIR}
  git remote add origin git://github.com/${DOC_REPO}
  git config core.sparsecheckout true
  echo "${DOC_SUBTREE}" >> .git/info/sparse-checkout
  git checkout -b ${DOC_BRANCH}
  git pull --depth 1 origin ${DOC_BRANCH}
)

# Generate report
generate_${REPORT//-/_}

# Exit early if not built on Travis to simplify
# local test runs of this script
if [[ ${LOCAL_BUILD} == true ]]; then
  echo "Local build, exiting early..."
  exit 1
fi

# Set up Git credentials
git config --global user.name "${GIT_NAME}"
git config --global user.email ${GIT_EMAIL}

# Commit the updated docs
cd $(dirname "${DOC_DIR}${DOC_SUBTREE}")
git add --all .
git commit -m "${REPORT//-/ }: Automatic update." || echo "No changes for ${REPORT//-/ }."
until (git pull --rebase origin ${DOC_BRANCH} &&
       git push -q https://${GH_TOKEN}@github.com/${DOC_REPO} ${DOC_BRANCH} &&
       echo "Pushed to ${DOC_REPO} ${DOC_BRANCH}."); do
  echo "Retry pushing to ${DOC_REPO} ${DOC_BRANCH}."
  sleep 1
done
