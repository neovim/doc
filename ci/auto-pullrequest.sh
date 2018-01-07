#!/usr/bin/env bash

# Automated pull requests

set -e
# set -x

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/neovim.sh

require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

# Fork of neovim/neovim (upstream) to which the PR will be pushed.
NEOVIM_FORK="${NEOVIM_FORK:-marvim}"
VIM_SOURCE_DIR="${VIM_SOURCE_DIR:-${NEOVIM_DIR}/.vim-src}"

# Updates src/nvim/version.c in the Nvim source tree.
# Commits the changes to branch "bot-ci-version-update".
# Configures "$NEOVIM_FORK/neovim" as a remote.
# Pushes the changes.
update_version_c() {
  local branch="bot-ci-version-update"

  if is_ci_build --silent ; then
    require_environment_variable GIT_NAME "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable GIT_EMAIL "${BASH_SOURCE[0]}" ${LINENO}
  fi

  (
    cd "$NEOVIM_DIR"
    git checkout master
    git pull --rebase
    2>/dev/null git branch -D "$branch" || true
    git checkout -b "$branch"

    # Clone the Vim repo.
    log_info 'run: scripts/vim-patch.sh -V'
    VIM_SOURCE_DIR="$VIM_SOURCE_DIR" ./scripts/vim-patch.sh -V

    # Run the version.c update script.
    log_info 'run: scripts/vimpatch.lua'
    VIM_SOURCE_DIR="$VIM_SOURCE_DIR" nvim -i NONE -u NONE --headless \
      +"luafile scripts/vimpatch.lua" +q

    if test -z "$(git diff)" ; then
      log_info 'update_version_c: no changes to version.c'
      return 1
    fi

    # Commit and push the changes.
    if prompt_key_local "commit and push to $NEOVIM_FORK:${branch} ?" ; then
      if is_ci_build --silent ; then
        git config --local user.name "${GIT_NAME}"
        git config --local user.email "${GIT_EMAIL}"
      fi
      git add --all
      git commit -m "$(printf 'version.c: update [ci skip]')"
      if ! has_gh_token ; then
        return "$(can_fail_without_private)"
      fi
      git remote add "$NEOVIM_FORK" "https://github.com/$NEOVIM_FORK/neovim.git" || true
      git push --force --set-upstream "$NEOVIM_FORK" HEAD:$branch
    fi
  )
}

tail_missing_vimpatches() {
  (
    cd "$NEOVIM_DIR"
    log_info 'run: scripts/vim-patch.sh -L'
    local patches="$(VIM_SOURCE_DIR="$VIM_SOURCE_DIR" ./scripts/vim-patch.sh -L)"
    log_info "Missing patches (tail):"
    echo "$patches" | tail
  )
}

main() {
  install_nvim_appimage
  install_hub
  clone_neovim

  if update_version_c ; then
    (
      cd "$NEOVIM_DIR"
      # Note: update_version_c configures marvim/neovim as a remote.
      create_pullrequest neovim:master "${NEOVIM_FORK}:bot-ci-version-update"
    )
  fi
  if is_ci_build "tail_missing_vimpatches" ; then
    tail_missing_vimpatches
  fi
}

main
