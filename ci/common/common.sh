# Common helper functions & environment variable defaults for all types of builds.

# Fail if an environment variable does not exist.
# ${1}: Environment variable.
# ${2}: Script file.
# ${3}: Line number.
require_environment_variable() {
  local variable_name="${1}"
  local variable_content="${!variable_name}"
  if [[ -z "${variable_content}" ]]; then
    echo "${variable_name} not set at ${2}:${3}, cannot continue!"
    echo "Maybe you need to source a script from ci/common."
    exit 1
  fi
}

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

CI_TARGET=${CI_TARGET:-$(basename ${0%.sh})}
MAKE_CMD=${MAKE_CMD:-"make -j2"}

# Check if currently performing CI or local build.
# ${1}: Task that is NOT executed if building locally.
#       Default: "installing dependencies"
# Return 0 if CI build, 1 otherwise.
is_ci_build() {
  if [[ ${CI} != true ]]; then
    echo "Local build, skip ${1:-installing dependencies}."
    return 1
  else
    return 0
  fi
}
