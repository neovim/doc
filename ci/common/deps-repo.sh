# Helper functions & environment variable defaults for builds using the deps repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

# OS X
DEPS_OSX64_REPO=${DEPS_OSX64_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_OSX64_BRANCH=${DEPS_OSX64_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_OSX64_DIR=${DEPS_OSX64_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS_OSX64_SUBTREE=${DEPS_OSX64_SUBTREE:-/osx-x64/}
DEPS_OSX64_SUDO=${DEPS_OSX64_SUDO:-sudo}

# Dependencies source code
DEPS_SRC_REPO=${DEPS_SRC_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_SRC_BRANCH=${DEPS_SRC_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_SRC_DIR=${DEPS_SRC_DIR:-${DEPS_DIR:-${BUILD_DIR}/neovim-deps}}
DEPS_SRC_SUBTREE=${DEPS_SRC_SUBTREE:-/src/}
DEPS_SRC_SUDO=${DEPS_SRC_SUDO:-}

# Build Neovim dependencies in an output directory.
# ${1}: Variable prefix (DEPS_<OS>64/DEPS_<OS>32).
# ${2}: Additional CMake flags (optional).
build_deps() {
  local prefix="${1}"
  local subtree="${prefix}_SUBTREE"
  local dir="${prefix}_DIR"

  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${subtree} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${dir} "${BASH_SOURCE[0]}" ${LINENO}

  local depsdir="${!dir}${!subtree}"
  depsdir=${depsdir%/*}
  rm -rf ${depsdir}
  mkdir ${depsdir}

  cd ${depsdir}
  cmake ${2} ${NEOVIM_DIR}/third-party/
  make

  rm -rf ./{build,CMakeFiles,CMakeCache.txt,cmake_install.cmake,Makefile,.third-party}
}

# Clone Neovim deps repo.
# ${1}: Variable prefix (DEPS_<OS>64/DEPS_<OS>32).
clone_deps() {
  local prefix="${1}"
  local dir="${prefix}_DIR"
  local repo="${prefix}_REPO"
  local branch="${prefix}_BRANCH"
  local sudo="${prefix}_SUDO"

  require_environment_variable ${dir} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${repo} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${branch} "${BASH_SOURCE[0]}" ${LINENO}

  if [[ ! -d "${!dir}/.git" || ! -w "${!dir}/.git" ]]; then
    prompt_key_local "Warning: continuing will delete and recreate ${!dir}!" && {
      ${!sudo} rm -rf "${!dir}"
      ${!sudo} mkdir -p "${!dir}"
      ${!sudo} chown ${USER} "${!dir}"
    }
  fi
  prompt_key_local "Warning: continuing will reset branch ${!branch} to ${!repo}:${!branch} in ${!dir}." && clone_subtree ${prefix}
}
