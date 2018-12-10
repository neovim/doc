# Functions and defaults for build dependencies on Travis CI.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

# Define directories where dependencies are installed to
DEPS_INSTALL_DIR=${DEPS_INSTALL_DIR:-${BUILD_DIR}/build/.deps}
DEPS_BIN_DIR=${DEPS_BIN_DIR:-${DEPS_INSTALL_DIR}/bin}
export PATH="${DEPS_BIN_DIR}:${PATH}"

# Used when Nvim is needed but we don't want to compile it.
install_nvim_appimage() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}
  if check_executable nvim; then
    log_info 'found in $PATH (skipping install): nvim'
    return 0
  fi
  local url='https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage'

  log_info 'installing nvim.appimage ...'
  if ! curl --silent -L -o "${DEPS_BIN_DIR}/nvim" "$url" ; then
    log_error "download failed: $url"
  fi

  chmod u+x "${DEPS_BIN_DIR}/nvim"
  stat "${DEPS_BIN_DIR}/nvim"

  if ! check_executable nvim; then
    log_error 'not in $PATH or not executable: nvim'
    exit 1
  fi
}

install_hub() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}
  if check_executable hub; then
    log_info 'found in $PATH (skipping install): hub'
    return 0
  fi
  local url='https://github.com/github/hub/releases/download/v2.3.0-pre10/hub-linux-386-2.3.0-pre10.tgz'

  log_info 'installing hub ...'
  mkdir -p "${DEPS_INSTALL_DIR}/hub"

  if ! curl -L --silent "$url" \
    | tar xzf - --strip-components=1 -C ${DEPS_INSTALL_DIR}/hub
  then
    log_error "download failed: $url"
  fi
  ln -fs ${DEPS_INSTALL_DIR}/hub/bin/hub ${DEPS_BIN_DIR}/hub
}
