# Helper functions & environment variable defaults for builds using the neovim repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

NEOVIM_DIR=${NEOVIM_DIR:-${BUILD_DIR}/build/neovim}
NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}

clone_neovim() {
  if is_ci_build || ! [ -d ${NEOVIM_DIR} ] ; then
    rm -rf ${NEOVIM_DIR}
    git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
  else
    git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD >/dev/null \
      || exit 1
  fi

  NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)
}
