# Functions and defaults for builds using the Neovim repo.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

export NEOVIM_DIR=${NEOVIM_DIR:-${BUILD_DIR}/build/neovim}
NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}

clone_neovim() {
  if is_ci_build || ! [ -d ${NEOVIM_DIR} ] ; then
    rm -rf ${NEOVIM_DIR}
    git clone --branch ${NEOVIM_BRANCH} git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
  else
    git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD >/dev/null \
      || exit 1
    # Note: `git pull` is intentionally omitted: not wanted for local dev.
  fi

  NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)
}
