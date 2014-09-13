# Helper functions & environment variable defaults for builds using the doc repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOC_DIR=${DOC_DIR:-${BUILD_DIR}/build/doc}
DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}

clone_doc() {
  rm -rf ${DOC_DIR}
  clone_subtree DOC
}

commit_doc() {
  commit_subtree DOC
}
