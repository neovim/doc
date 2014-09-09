# Common helper functions & environment variable defaults for documentation builds.

# Check if currently performing CI or local build.
# ${1}: Task that is NOT executed if building locally.
#       Default: "installing dependencies"
# Return 0 if CI build, 1 otherwise.
is_ci_build?() {
  if [[ ${CI} != true ]]; then
    echo "Local build, skip ${1:-installing dependencies}."
    return 1
  else
    return 0
  fi
}

clone_doc() {(
  rm -rf ${DOC_DIR}
  git init ${DOC_DIR}
  cd ${DOC_DIR}
  git remote add origin git://github.com/${DOC_REPO}
  git config core.sparsecheckout true
  echo "${DOC_SUBTREE}" >> .git/info/sparse-checkout
  git checkout -b ${DOC_BRANCH}
  git pull --depth 1 origin ${DOC_BRANCH}
)}

clone_neovim() {
  rm -rf ${NEOVIM_DIR}
  git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
  NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)
}

commit_doc() {
  is_ci_build? "committing to doc repo" && (

  if [[ -z "${GH_TOKEN}" ]]; then
    echo "GH_TOKEN not set, not committing."
    echo "To test pull requests, see instructions in README.md."
    exit 1
  fi

  cd $(dirname "${DOC_DIR}${DOC_SUBTREE}")

  git config --local user.name ${GIT_NAME}
  git config --local user.email ${GIT_EMAIL}

  git add --all .
  git commit -m "${CI_TARGET//-/ }: Automatic update." && {
    until (git pull --rebase origin ${DOC_BRANCH} &&
           git push https://${GH_TOKEN}@github.com/${DOC_REPO} ${DOC_BRANCH} >/dev/null 2>&1 &&
           echo "Pushed to ${DOC_REPO} ${DOC_BRANCH}."); do
      echo "Retry pushing to ${DOC_REPO} ${DOC_BRANCH}."
      sleep 1
    done
  } || echo "No changes for ${CI_TARGET//-/ }."
)}

if [[ -z "${BUILD_DIR}" ]]; then
  echo "BUILD_DIR not set, cannot continue!"
  echo "You need to set BUILD_DIR before including this file (${BASH_SOURCE[0]})."
  exit 1
fi

# Set environment variable defaults
CI_TARGET=${CI_TARGET:-$(basename ${0%.sh})}
NEOVIM_DIR=${NEOVIM_DIR:-${BUILD_DIR}/build/neovim}
NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}
DOC_DIR=${DOC_DIR:-${BUILD_DIR}/build/doc}
DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}
MAKE_CMD=${MAKE_CMD:-"make -j2"}
GIT_NAME=${GIT_NAME:-marvim}
GIT_EMAIL=${GIT_EMAIL:-marvim@users.noreply.github.com}

source ${BUILD_DIR}/ci/common/dependencies.sh
