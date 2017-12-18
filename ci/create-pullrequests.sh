#!/usr/bin/env bash

# This task creates automated pull requests for:
#   - src/nvim/version.c
#   - runtime/doc/api.txt

set -e
# set -x

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/neovim.sh

require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

NEOVIM_REPO="${NEOVIM_REPO:-marvim/neovim}"
VIM_SOURCE_DIR="${VIM_SOURCE_DIR:-${NEOVIM_DIR}/.vim-src}"

# Updates src/nvim/version.c in the Nvim source tree.
#
# Fails if no changes were made.
update_version_c() {
  local branch="version-update"

  if is_ci_build --silent ; then
    require_environment_variable GIT_NAME "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable GIT_EMAIL "${BASH_SOURCE[0]}" ${LINENO}
  fi

  (
    cd "$NEOVIM_DIR"
    git checkout master

    # Clone the Vim repo.
    echo 'run: scripts/vim-patch.sh -V'
    VIM_SOURCE_DIR="$VIM_SOURCE_DIR" ./scripts/vim-patch.sh -V

    # Run the version.c update script.
    echo 'run: scripts/vimpatch.lua'
    VIM_SOURCE_DIR="$VIM_SOURCE_DIR" nvim -i NONE -u NONE --headless \
      +"luafile scripts/vimpatch.lua" +q

    if test -z "$(git diff)" ; then
      echo 'update_version_c: no changes to version.c'
      return 1
    fi

    # Commit the changes, if any.
    if prompt_key_local "Commit and push the results to $NEOVIM_REPO:${branch} ?" ; then
      if is_ci_build --silent ; then
        git config --local user.name "${GIT_NAME}"
        git config --local user.email "${GIT_EMAIL}"
      fi
      git add --all
      git commit -m 'version.c: update'
    fi
  )
}

tail_missing_vimpatches() {
  (
    cd "$NEOVIM_DIR"
    echo 'run: scripts/vim-patch.sh -L'
    local patches="$(VIM_SOURCE_DIR="$VIM_SOURCE_DIR" ./scripts/vim-patch.sh -L)"
    echo "Missing patches (last 10):"
    echo "$patches" | tail
  )
}

is_ci_build && {
  install_doxygen
}

install_nvim
clone_neovim
if update_version_c ; then
  create_pullrequest
fi
if is_ci_build "tail_missing_vimpatches" ; then
  tail_missing_vimpatches
fi
