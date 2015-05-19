# Helper functions & environment variable defaults for builds using the deps repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

# Linux
DEPS_LINUX64_REPO=${DEPS_LINUX64_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_LINUX64_BRANCH=${DEPS_LINUX64_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_LINUX64_DIR=${DEPS_LINUX64_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS_LINUX64_SUBTREE=${DEPS_LINUX64_SUBTREE:-/linux-x64/}
DEPS_LINUX32_REPO=${DEPS_LINUX32_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_LINUX32_BRANCH=${DEPS_LINUX32_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_LINUX32_DIR=${DEPS_LINUX32_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS_LINUX32_SUBTREE=${DEPS_LINUX32_SUBTREE:-/linux-x86/}

# OS X
DEPS_OSX64_REPO=${DEPS_OSX64_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_OSX64_BRANCH=${DEPS_OSX64_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_OSX64_DIR=${DEPS_OSX64_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS_OSX64_SUBTREE=${DEPS_OSX64_SUBTREE:-/osx-x64/}

# Dependencies source code
DEPS_SRC_REPO=${DEPS_SRC_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS_SRC_BRANCH=${DEPS_SRC_BRANCH:-${DEPS_BRANCH:-master}}
DEPS_SRC_DIR=${DEPS_SRC_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS_SRC_SUBTREE=${DEPS_SRC_SUBTREE:-/src/}

# Set up prebuilt 64-bit Neovim dependencies.
setup_deps64() {
  local deps_dir="DEPS_${CI_OS^^}64_DIR"
  local deps_subtree="DEPS_${CI_OS^^}64_SUBTREE"
  local deps_repo="DEPS_${CI_OS^^}64_REPO"
  local deps_branch="DEPS_${CI_OS^^}64_BRANCH"

  local deps_path="${!deps_dir}${!deps_subtree}"

  NVIM_DEPS_REPO="${!deps_repo}" \
  NVIM_DEPS_BRANCH="${!deps_branch}" \
  source "${BUILD_DIR}/scripts/travis-setup.sh" && \
  _setup_deps "${deps_path}"
}

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

  require_environment_variable ${dir} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${repo} "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable ${branch} "${BASH_SOURCE[0]}" ${LINENO}

  if [[ ! -d "${!dir}/.git" || ! -w "${!dir}/.git" ]]; then
    prompt_key_local "Warning: continuing will delete and recreate ${!dir}!" && {
      sudo rm -rf "${!dir}"
      sudo mkdir -p "${!dir}"
      sudo chown ${USER} "${!dir}"
    }
  fi
  prompt_key_local "Warning: continuing will reset branch ${!branch} to ${!repo}:${!branch} in ${!dir}." && clone_subtree ${prefix}
}
