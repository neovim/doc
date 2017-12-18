# Functions and defaults for builds using the neovim repo.

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/common/common.sh

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

NEOVIM_DIR=${NEOVIM_DIR:-${BUILD_DIR}/build/neovim}
NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}

clone_neovim() {
  if is_ci_build || ! [ -d ${NEOVIM_DIR} ] ; then
    rm -rf ${NEOVIM_DIR}
    git clone --branch ${NEOVIM_BRANCH} git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
  else
    git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD >/dev/null \
      || exit 1
  fi

  NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)
}

# Used when Nvim is needed but we don't want to compile it.
require_nvim() {
  if ! check_executable nvim; then
    mkdir -p "${BUILD_DIR}/bin"
    curl -L -o "${BUILD_DIR}/bin/nvim" \
      https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
    export PATH="${BUILD_DIR}/bin:${PATH}"

    if check_executable nvim; then
      >&2 echo 'require_nvim: "nvim" not in $PATH '
      exit 1
    fi
  fi
}
