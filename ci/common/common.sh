# Common helper functions & environment variable defaults for all types of builds.

# Fail if an environment variable does not exist.
# ${1}: Environment variable.
# ${2}: Script file.
# ${3}: Line number.
require_environment_variable() {
  local variable_name="${1}"
  eval "local variable_content=\"\${${variable_name}:-}\""
  if [[ -z "${variable_content}" ]]; then
    >&2 echo "${variable_name} not set at ${2}:${3}, cannot continue!"
    >&2 echo "Maybe you need to source a script from ci/common."
    exit 1
  fi
}

# Output the current OS.
# Possible values are "osx" and "linux".
get_os() {
  local os="$(uname -s)"
  if [[ "${os}" == "Darwin" ]]; then
    echo "osx"
  else
    echo "linux"
  fi
}

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

CI_TARGET=${CI_TARGET:-$(basename ${0%.sh})}
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
      echo "Local build, skip $msg."
    fi
    return 1
  fi
  return 0
}

# Clone a Git repository and check out a subtree.
# ${1}: Variable prefix.
clone_subtree() {(
  local prefix="${1}"
  local subtree="${prefix}_SUBTREE"
  local dir="${prefix}_DIR"
  local repo="${prefix}_REPO"
  local branch="${prefix}_BRANCH"

  require_environment_variable ${subtree} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${dir} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${repo} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${branch} "${BASH_SOURCE[0]}" ${LINENO}

  [ -d "${!dir}/.git" ] || git init "${!dir}"
  cd "${!dir}" 
  git rev-parse HEAD >/dev/null 2>&1 && git reset --hard HEAD

  is_ci_build "Git subtree" && {
    git config core.sparsecheckout true
    echo "${!subtree}" > .git/info/sparse-checkout
  }
  git checkout -B ${!branch}
  git pull --rebase --force git://github.com/${!repo} ${!branch}
)}

# Prompt the user to press a key to continue for local builds.
# ${1}: Shown message.
prompt_key_local() {
  if ! is_ci_build --silent ; then
    echo "${1}"
    echo "Press a key to continue, CTRL-C to abort..."
    read -n 1 -s
  fi
}

# Check whether absense of private (i.e. encrypted) data should fail the build
# Targets for use like `exit $(can_fail_without_private)` or `return
# $(can_fail_without_private)`.
can_fail_without_private() {
  if test "$TRAVIS_EVENT_TYPE" = pull_request ; then
    echo 0
  else
    echo 1
  fi
}

# Commit and push to a Git repo checked out using clone_subtree.
# ${1}: Variable prefix.
commit_subtree() {(
  local prefix="${1}"
  local subtree="${prefix}_SUBTREE"
  local dir="${prefix}_DIR"
  local repo="${prefix}_REPO"
  local branch="${prefix}_BRANCH"

  require_environment_variable CI_TARGET "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable GIT_NAME "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable GIT_EMAIL "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${subtree} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${dir} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${repo} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${branch} "${BASH_SOURCE[0]}" ${LINENO}

  cd "${!dir}"

  git add --all "./${!subtree}"

  if is_ci_build --silent ; then
    # Commit on Travis CI.
    git config --local user.name ${GIT_NAME}
    git config --local user.email ${GIT_EMAIL}

    git commit -m "${CI_TARGET//-/ }: Automatic update." || true

    local attempts=10

    while test $(( attempts-=1 )) -gt 0 ; do
      if git pull --rebase git://github.com/${!repo} ${!branch} ; then
        if ! has_gh_token ; then
          echo "GH_TOKEN not set, not committing."
          echo "To test pull requests, see instructions in README.md."
          return $(can_fail_without_private)
        fi
        if with_token git push https://%token%@github.com/${!repo} ${!branch}
        then
          echo "Pushed to ${!repo} ${!branch}."
          return 0
        fi
      fi
      echo "Retry pushing to ${!repo} ${!branch}."
      sleep 1
    done
    return 1
  else
    if prompt_key_local "Build finished, do you want to commit and push the results to ${!repo}:${!branch} (change by setting ${repo}/${branch})?" ; then
    # Commit in local builds.
      git commit || true
      git push ssh://git@github.com/${!repo} ${!branch}
    fi
  fi
)}

with_token() {(
  set +x
  set +o pipefail
  if [[ $1 = --empty-unset ]] ; then
    : ${GH_TOKEN:=}
    shift
  else
    set -u
    : ${GH_TOKEN}
  fi
  for arg ; do
    arg="${arg//%token%/$GH_TOKEN}"
    printf '%s\0' "$arg"
  done | xargs -0 -x sh -c '"$@"' - >&2 | sed "s/$GH_TOKEN/GH_TOKEN/g"
  return ${PIPESTATUS[1]}
)}

has_gh_token() {
  with_token --empty-unset test -n %token%
}
