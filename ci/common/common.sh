#!/usr/bin/env bash

# Common functions and environment variable defaults for all types of builds.

# Fail if an environment variable does not exist.
# ${1}: Environment variable.
# ${2}: Script file.
# ${3}: Line number.
require_environment_variable() {
  local variable_name="${1}"
  eval "local variable_content=\"\${${variable_name}:-}\""
  # shellcheck disable=2154
  if [[ -z "${variable_content}" ]]; then
    >&2 echo "${2}:${3}: missing env var: ${variable_name}"
    >&2 echo "Maybe you need to source a script from ci/common."
    exit 1
  fi
}

# Checks if a program is in $PATH and is executable.
check_executable() {
  test -x "$(command -v "${1}")"
}

log_info() {
  printf "bot-ci: %s\n" "$@"
}

log_error() {
  >&2 printf "bot-ci: error: %s\n" "$@"
}

# Output the current OS.
# Possible values are "osx" and "linux".
get_os() {
  local os
  os="$(uname -s)"
  if [[ "${os}" == "Darwin" ]]; then
    echo "osx"
  else
    echo "linux"
  fi
}

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

CI_TARGET=${CI_TARGET:-$(basename "${0%.sh}")}
CI_OS=${TRAVIS_OS_NAME:-$(get_os)}
MAKE_CMD=${MAKE_CMD:-"make -j2"}
GIT_NAME=${GIT_NAME:-marvim}
GIT_EMAIL=${GIT_EMAIL:-marvim@users.noreply.github.com}

# Check if currently performing CI or local build.
# ${1}: Task that is NOT executed if building locally.
#       Default: "installing dependencies". Not reported if equal to --silent.
# Return 0 if CI build, 1 otherwise.
is_ci_build() {
  local msg="${1:-installing dependencies}"
  if test "${CI:-}" != "true" ; then
    if test "$msg" != "--silent" ; then
      log_info "Local build, skip $msg"
    fi
    return 1
  fi
  return 0
}

git_truncate() {
  local branch="${1}"
  local new_root
  local old_head
  if ! old_head=$(git rev-parse "$branch") ; then
    >&2 echo "error: git_truncate: invalid branch: $1"
    exit 1
  fi
  if ! new_root=$(git rev-parse "$2") ; then
    >&2 echo "error: git_truncate: invalid branch: $2"
    exit 1
  fi
  git checkout --orphan temp "$new_root"
  git commit -m "truncate history"
  git rebase --onto temp "$new_root" "$branch"
  git branch -D temp
  >&2 echo "git_truncate: new_root: $new_root"
  >&2 echo "git_truncate: old HEAD: $old_head"
  >&2 echo "git_truncate: new HEAD: $(git rev-parse HEAD)"
}

# Clone a Git repository and check out a subtree.
# ${1}: Variable prefix.
clone_subtree() {
  (
    local prefix="${1}"
    local subtree="${prefix}_SUBTREE"
    local dir="${prefix}_DIR"
    local repo="${prefix}_REPO"
    local branch="${prefix}_BRANCH"

    require_environment_variable "${subtree}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${dir}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${repo}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${branch}" "${BASH_SOURCE[0]}" ${LINENO}

    [ -d "${!dir}/.git" ] || git init "${!dir}"
    cd "${!dir}" || return
    git rev-parse HEAD >/dev/null 2>&1 && git reset --hard HEAD

    is_ci_build "Git subtree" && {
      git config core.sparsecheckout true
      echo "${!subtree}" > .git/info/sparse-checkout
    }
    git checkout -B "${!branch}"
    git pull --rebase --force "git://github.com/${!repo}" "${!branch}"
  )
}

# Prompt the user to press a key to continue for local builds.
# ${1}: Shown message.
prompt_key_local() {
  if ! is_ci_build --silent ; then
    log_info "${1}"
    log_info "Press a key to continue, CTRL-C to abort..."
    read -r -n 1 -s
  fi
}

# Check whether absence of private (i.e. encrypted) data should fail the build.
# Echoes 0 in case of pull requests, 1 otherwise.
# Usage examples:
# - `exit $(can_fail_without_private)`
# - `return $(can_fail_without_private)`
can_fail_without_private() {
  if [ "$TRAVIS_EVENT_TYPE" = pull_request ]; then
    echo 0
  else
    echo 1
  fi
}

# Commit and push to a Git repo checked out using clone_subtree.
#
# ${1}: Variable prefix.
# ${2}: (optional) Number of retries.
# ${3}: (optional) Extra arguments to "git push". If this contains
#       "--force" then "git pull" is not attempted.
commit_subtree() {
  (
    local prefix="${1}"
    local attempts="${2:-10}"
    local push_args="${3:-}"
    local subtree="${prefix}_SUBTREE"
    local dir="${prefix}_DIR"
    local repo="${prefix}_REPO"
    local branch="${prefix}_BRANCH"

    require_environment_variable CI_TARGET "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable GIT_NAME "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable GIT_EMAIL "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${subtree}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${dir}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${repo}" "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable "${branch}" "${BASH_SOURCE[0]}" ${LINENO}

    cd "${!dir}" || return

    git add --all "./${!subtree}"

    if is_ci_build --silent ; then
      # Commit on Travis CI.
      git config --local user.name "${GIT_NAME}"
      git config --local user.email "${GIT_EMAIL}"

      git commit -m "${CI_TARGET//-/ }: Automatic update" || true

      while test $(( attempts-=1 )) -ge 0 ; do
        if echo "${push_args}" | >/dev/null 2>&1 grep -- '--force' \
            || git pull --rebase "git://github.com/${!repo}" "${!branch}" ; then
          if ! has_gh_token ; then
            log_info 'GH_TOKEN not set; push skipped'
            log_info 'To test pull requests, see instructions in README.md'
            return "$(can_fail_without_private)"
          fi
          if git push ${push_args} "https://github.com/${!repo}" "${!branch}"
          then
            log_info "Pushed to: ${!repo} ${!branch}"
            return 0
          fi
        fi
        if test $attempts -gt 0 ; then
          log_info "Retry push to: ${!repo} ${!branch}"
        fi
        sleep 1
      done
      return 1
    else
      if prompt_key_local "Build finished, do you want to commit and push the results to ${!repo}:${!branch} (change by setting ${repo}/${branch})?" ; then
      # Commit in local builds.
        git commit || true
        git push "ssh://git@github.com/${!repo}" "${!branch}"
      fi
    fi
  )
}

# Creates a pull request from current HEAD.
# Current directory must be a git repo.
#
# ${1}: base, in github_user:branch format
# ${2}: head, in github_user:branch format
create_pullrequest() {
  local base="${1:-}"
  local head="${2:-}"
  require_environment_variable base "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable head "${BASH_SOURCE[0]}" ${LINENO}

  if ! check_executable hub; then
    log_error 'create_pullrequest: "hub" not in $PATH or not executable.'
    exit 1
  fi

  (
    set +o xtrace
    local rv pr_message

    pr_message="$(printf '%s\n\nThis pull request is [automated](https://github.com/neovim/bot-ci).' "$(git log -1 --format='%s')")"

    if ! has_gh_token ; then
      log_info 'missing $GH_TOKEN, skipping pull-request'
      return "$(can_fail_without_private)"
    fi

    log_info "create_pullrequest: creating pull-request ..."
    GITHUB_TOKEN="$GH_TOKEN" hub pull-request \
      -m "$pr_message" \
      -b "$base" \
      -h "$head" \
      || true  # Ignore failure.
  )
}

has_gh_token() {
  (
    set +o xtrace
    2>&1 >/dev/null test -n "$GH_TOKEN"
  )
}
