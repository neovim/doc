# Functions and defaults for build dependencies on Travis CI.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOXYGEN_VERSION=${DOXYGEN_VERSION:-1.8.7}
GIT_BZR_NG_VERSION=${GIT_BZR_NG_VERSION:-9878a3052f4d93f4332f6c92395c8f904156d3c8}

# Define directories where dependencies are installed to
DEPS_INSTALL_DIR=${DEPS_INSTALL_DIR:-${BUILD_DIR}/build/.deps}
DEPS_BIN_DIR=${DEPS_BIN_DIR:-${DEPS_INSTALL_DIR}/bin}
export PATH="${DEPS_BIN_DIR}:${PATH}"

install_doxygen() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}

  log_info "installing Doxygen ${DOXYGEN_VERSION} ..."
  mkdir -p ${DEPS_INSTALL_DIR}/doxygen
  wget -q -O - http://ftp.stack.nl/pub/users/dimitri/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz \
    | tar xzf - --strip-components=1 -C ${DEPS_INSTALL_DIR}/doxygen
  ln -fs ${DEPS_INSTALL_DIR}/doxygen/bin/doxygen ${DEPS_BIN_DIR}/doxygen
}

install_git_bzr() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}

  log_info "installing git-bzr-ng ..."
  mkdir -p ${DEPS_INSTALL_DIR}/git-bzr-ng
  wget -q -O - https://github.com/termie/git-bzr-ng/archive/${GIT_BZR_NG_VERSION}.tar.gz \
    | tar xzf - --strip-components=1 -C ${DEPS_INSTALL_DIR}/git-bzr-ng
  ln -fs ${DEPS_INSTALL_DIR}/git-bzr-ng/git-bzr ${DEPS_BIN_DIR}/git-bzr
}

# Used when Nvim is needed but we don't want to compile it.
install_nvim_appimage() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}
  # if check_executable nvim; then
  #   log_info 'skipping install, found in $PATH: nvim'
  #   return 0
  # fi
  local nvim_url='https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage'

  log_info 'installing nvim.appimage ...'
  if ! curl --silent -L -o "${DEPS_BIN_DIR}/nvim" "$nvim_url" ; then
    log_error "download failed: $nvim_url"
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
    log_info 'skipping install, found in $PATH: hub'
    return 0
  fi

  curl -L -o 'https://github.com/github/hub/releases/download/v2.3.0-pre10/hub-linux-386-2.3.0-pre10.tgz'
}
