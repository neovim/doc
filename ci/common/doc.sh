# Functions for automating the https://github.com/neovim/doc/ repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOC_DIR=${DOC_DIR:-${BUILD_DIR}/build/doc}
DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}

# Keep the https://github.com/neovim/doc/ repository history trimmed, otherwise
# it gets huge and slow to clone.  We don't care about its commit history.
#
# NOTE: Do this after ALL other reports were pushed, otherwise their
#       respective commit_subtree ("git pull --rebase") steps will fail.
try_truncate_history() {
  cd "${DOC_DIR}" || { log_error "try_truncate_history: cd failed"; exit 1; }
  local attempts=4
  local branch=gh-pages
  if NEW_ROOT=$(2>/dev/null git rev-parse "$branch"~11) ; then
    git fetch https://github.com/neovim/doc "$branch"
    git reset --hard FETCH_HEAD
    git_truncate "$branch" "$branch"~10
  else
    log_info "try_truncate_history: branch ${branch} has too few commits, skipping truncate"
  fi
}
