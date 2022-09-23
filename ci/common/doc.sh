# Functions for automating the https://github.com/neovim/doc/ repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOC_DIR=${DOC_DIR:-${BUILD_DIR}/build/doc}
DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}

# Trim the https://github.com/neovim/doc/ repository history, els it gets huge
# and slow to clone.  We don't care about the history of the `gh-pages` branch.
try_truncate_history() {
  cd "${DOC_DIR}" || { log_error "try_truncate_history: cd failed"; exit 1; }
  local branch=gh-pages
  if NEW_ROOT=$(2>/dev/null git rev-parse "$branch"~11) ; then
    git_truncate "$branch" "$branch"~10
  else
    log_info "try_truncate_history: branch ${branch} has too few commits, skipping truncate"
  fi
}
