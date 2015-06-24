# Helper functions & environment variable defaults for build dependencies on Travis.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

DOXYGEN_VERSION=${DOXYGEN_VERSION:-1.8.7}
CLANG_VERSION=${CLANG_VERSION:-3.5}

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
  ln -fs ${DEPS_INSTALL_DIR}/doxygen/bin/doxygen ${DEPS_BIN_DIR}
}

install_clang() {
  mkdir -p ${DEPS_BIN_DIR}

  echo "Installing Clang ${CLANG_VERSION}..."
  sudo add-apt-repository "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu precise main"
  sudo add-apt-repository "deb http://llvm.org/apt/precise/ llvm-toolchain-precise-${CLANG_VERSION} main"
  wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
  sudo apt-get update -qq
  sudo apt-get install -y -q clang-${CLANG_VERSION}

  ln -fs /usr/bin/clang-${CLANG_VERSION} ${DEPS_BIN_DIR}/clang
  ln -fs /usr/bin/scan-build-${CLANG_VERSION} ${DEPS_BIN_DIR}/scan-build
}

install_gcc_multilib() {
  mkdir -p ${DEPS_BIN_DIR}

  echo "Installing multilib GCC/G++."
  sudo apt-get update -qq
  sudo apt-get install -y -q gcc-multilib g++-multilib

  ln -fs /usr/bin/gcc ${DEPS_BIN_DIR}
  ln -fs /usr/bin/g++ ${DEPS_BIN_DIR}
  ln -fs ${DEPS_BIN_DIR}/gcc ${DEPS_BIN_DIR}/cc
  ln -fs ${DEPS_BIN_DIR}/g++ ${DEPS_BIN_DIR}/c++
}

install_git_bzr() {
  echo "Installing git-bzr-ng..."
  sudo add-apt-repository "deb http://ppa.launchpad.net/fwalch/git-bzr-ng/ubuntu precise main"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF82DF84
  sudo apt-get update -qq
  sudo apt-get install -y -q git-bzr-ng
}
