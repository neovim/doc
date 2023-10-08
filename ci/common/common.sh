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
    log_error "${2}:${3}: missing env var: ${variable_name}
    Maybe you need to source a script from ci/common?"
    exit 1
  fi
}

log_info() {
  printf "ci: %s\n" "$@"
}

log_error() {
  >&2 printf "ci: error: %s\n" "$@"
}

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

CI_TARGET=${CI_TARGET:-$(basename "${0%.sh}")}
GIT_NAME=${GIT_NAME:-marvim}
GIT_EMAIL=${GIT_EMAIL:-marvim@users.noreply.github.com}

git_truncate() {
  local branch="${1}"
  local new_root
  local old_head
  if ! old_head=$(git rev-parse "$branch") ; then
    log_error "git_truncate: invalid branch: $1"
    exit 1
  fi
  if ! new_root=$(git rev-parse "$2") ; then
    log_error "git_truncate: invalid branch: $2"
    exit 1
  fi
  git checkout --orphan temp "$new_root"
  git commit -m "truncate history"
  git rebase --onto temp "$new_root" "$branch"
  git branch -D temp
  log_info "git_truncate: new_root: $new_root"
  log_info "git_truncate: old HEAD: $old_head"
  log_info "git_truncate: new HEAD: $(git rev-parse HEAD)"
}
