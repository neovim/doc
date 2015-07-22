# See https://github.com/neovim/bot-ci#nightly-builds for more information.
nightly_x64() {
  mkdir "${TRAVIS_BUILD_DIR}/_neovim"
  wget -q -O - https://github.com/neovim/neovim/releases/download/nightly/neovim-${TRAVIS_OS_NAME}64.tar.gz \
    | tar xzf - --strip-components=1 -C "${TRAVIS_BUILD_DIR}/_neovim"

  export PATH="${TRAVIS_BUILD_DIR}/_neovim/bin:${PATH}"
  echo "\$PATH: \"${PATH}\""

  export VIM="${TRAVIS_BUILD_DIR}/_neovim/share/nvim/runtime"
  echo "\$VIM: \"${VIM}\""

  nvim --version
}

_setup_deps() {
  NVIM_DEPS_REPO="${NVIM_DEPS_REPO:-neovim/deps}"
  NVIM_DEPS_BRANCH="${NVIM_DEPS_BRANCH:-master}"
  echo "Setting up prebuilt dependencies from ${NVIM_DEPS_REPO}:${NVIM_DEPS_BRANCH}."

  sudo git clone --depth 1 --branch ${NVIM_DEPS_BRANCH} git://github.com/${NVIM_DEPS_REPO} "$(dirname "${1}")"

  export NVIM_DEPS_PREFIX="${1}/usr"
  echo "\$NVIM_DEPS_PREFIX: \"${NVIM_DEPS_PREFIX}\""

  eval "$(${NVIM_DEPS_PREFIX}/bin/luarocks path)"
  echo "\$LUA_PATH: \"${LUA_PATH}\""
  echo "\$LUA_CPATH: \"${LUA_CPATH}\""

  export PKG_CONFIG_PATH="${NVIM_DEPS_PREFIX}/lib/pkgconfig"
  echo "\$PKG_CONFIG_PATH: \"${PKG_CONFIG_PATH}\""

  export USE_BUNDLED_DEPS=OFF
  echo "\$USE_BUNDLED_DEPS: \"${USE_BUNDLED_DEPS}\""

  export PATH="${NVIM_DEPS_PREFIX}/bin:${PATH}"
  echo "\$PATH: \"${PATH}\""
}

deps_x64() {
  if [ "${TRAVIS_OS_NAME}" != "osx" ]; then
    >&2 echo "Prebuilt dependencies are only supported for OS X."
    exit 1
  fi
  _setup_deps "/opt/neovim-deps/osx-x64"
}

_call_function() {
  _fun_name=$(echo "${1}" | tr '-' '_')
  ${_fun_name}
}

_call_function
