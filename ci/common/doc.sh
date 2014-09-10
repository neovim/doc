# Helper functions & environment variable defaults for builds using the doc repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOC_DIR=${DOC_DIR:-${BUILD_DIR}/build/doc}
DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}
GIT_NAME=${GIT_NAME:-marvim}
GIT_EMAIL=${GIT_EMAIL:-marvim@users.noreply.github.com}

clone_doc() {(
  require_environment_variable DOC_SUBTREE "${BASH_SOURCE[0]}" ${LINENO}

  rm -rf ${DOC_DIR}
  git init ${DOC_DIR}
  cd ${DOC_DIR}
  git remote add origin git://github.com/${DOC_REPO}
  git config core.sparsecheckout true
  echo "${DOC_SUBTREE}" >> .git/info/sparse-checkout
  git checkout -b ${DOC_BRANCH}
  git pull --depth 1 origin ${DOC_BRANCH}
)}

commit_doc() {
  require_environment_variable CI_TARGET "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable DOC_SUBTREE "${BASH_SOURCE[0]}" ${LINENO}

  is_ci_build "committing to doc repo" && (

  if [[ -z "${GH_TOKEN}" ]]; then
    echo "GH_TOKEN not set, not committing."
    echo "To test pull requests, see instructions in README.md."
    return 1
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
