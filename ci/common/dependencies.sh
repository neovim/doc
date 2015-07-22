# Helper functions & environment variable defaults for build dependencies on Travis.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOXYGEN_VERSION=${DOXYGEN_VERSION:-1.8.7}
GIT_BZR_NG_VERSION=${GIT_BZR_NG_VERSION:-9878a3052f4d93f4332f6c92395c8f904156d3c8}

# Define directories where dependencies are installed to
DEPS_INSTALL_DIR=${DEPS_INSTALL_DIR:-${BUILD_DIR}/build/.deps}
DEPS_BIN_DIR=${DEPS_BIN_DIR:-${DEPS_INSTALL_DIR}/bin}
export PATH="${DEPS_BIN_DIR}:${PATH}"

install_doxygen() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}

  echo "Installing Doxygen ${DOXYGEN_VERSION}..."
  mkdir -p ${DEPS_INSTALL_DIR}/doxygen
  wget -q -O - http://ftp.stack.nl/pub/users/dimitri/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz \
    | tar xzf - --strip-components=1 -C ${DEPS_INSTALL_DIR}/doxygen
  ln -fs ${DEPS_INSTALL_DIR}/doxygen/bin/doxygen ${DEPS_BIN_DIR}/doxygen
}

install_git_bzr() {
  mkdir -p ${DEPS_INSTALL_DIR} ${DEPS_BIN_DIR}

  echo "Installing git-bzr-ng..."
  mkdir -p ${DEPS_INSTALL_DIR}/git-bzr-ng
  wget -q -O - https://github.com/termie/git-bzr-ng/archive/${GIT_BZR_NG_VERSION}.tar.gz \
    | tar xzf - --strip-components=1 -C ${DEPS_INSTALL_DIR}/git-bzr-ng
  ln -fs ${DEPS_INSTALL_DIR}/git-bzr-ng/git-bzr ${DEPS_BIN_DIR}/git-bzr
}
