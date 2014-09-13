# Helper functions & environment variable defaults for builds using the deps repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DEPS64_REPO=${DEPS64_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS64_BRANCH=${DEPS64_BRANCH:-${DEPS_BRANCH:-master}}
DEPS64_DIR=${DEPS64_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS64_SUBTREE=${DEPS64_SUBTREE:-/64/}
DEPS32_REPO=${DEPS32_REPO:-${DEPS_REPO:-neovim/deps}}
DEPS32_BRANCH=${DEPS32_BRANCH:-${DEPS_BRANCH:-master}}
DEPS32_DIR=${DEPS32_DIR:-${DEPS_DIR:-/opt/neovim-deps}}
DEPS32_SUBTREE=${DEPS32_SUBTREE:-/32/}

# Set up prebuilt 64-bit Neovim dependencies.
setup_deps64() {
  echo "Setting up prebuilt dependencies from ${DEPS64_REPO} ${DEPS64_BRANCH}..."

  sudo git clone --branch ${DEPS64_BRANCH} --depth 1 git://github.com/${DEPS64_REPO} ${DEPS64_DIR}
  local depsdir="${DEPS64_DIR}${DEPS64_SUBTREE}"
  depsdir=${depsdir%/*}
  eval $(${depsdir}/usr/bin/luarocks path)
  export PKG_CONFIG_PATH="${depsdir}/usr/lib/pkgconfig"
  export USE_BUNDLED_DEPS=OFF
  export PATH="${depsdir}/usr/bin:${PATH}"
}

# Build Neovim dependencies in an output directory.
# ${1}: Variable prefix (DEPS64/DEPS32).
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
  cd ${NEOVIM_DIR}
  make deps DEPS_CMAKE_FLAGS="-DDEPS_DIR=${depsdir} ${2}"
  rm -rf ${depsdir}/build
}

# Clone Neovim deps repo.
# ${1}: Variable prefix (DEPS64/DEPS32).
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
  prompt_key_local "Warning: continuing will reset branch ${!branch} to ${!repo} ${!branch} in ${!dir}." && clone_subtree ${prefix}
}
