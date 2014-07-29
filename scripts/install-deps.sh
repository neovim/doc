#!/bin/bash -e

# Install necessary dependencies for scripts/publish-docs.sh
# on Travis CI.
#
# Required environment variables:
# ${ENVIRONMENT_FILE}: see .travis.yml
# ${TRAVIS_BUILD_DIR}

DOXYGEN_VERSION=1.8.7
CLANG_VERSION=3.4
NEOVIM_DEPS_REPO=neovim/deps
NEOVIM_DEPS_BRANCH=master
NEOVIM_DEPS_DIR=/opt/neovim-deps

mkdir -p ${TRAVIS_BUILD_DIR}/deps/bin
cd ${TRAVIS_BUILD_DIR}/deps

# Install doxygen
echo "Installing Doxygen ${DOXYGEN_VERSION}..."
mkdir -p doxygen
wget -q -O - http://ftp.stack.nl/pub/users/dimitri/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz \
  | tar xzf - --strip-components=1 -C doxygen
ln -fs ${PWD}/doxygen/bin/doxygen ${PWD}/bin

# Install scan-build from PPA
echo "Installing Clang ${CLANG_VERSION}..."
sudo add-apt-repository 'deb http://llvm.org/apt/precise/ llvm-toolchain-precise main'
wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install -y -q clang-${CLANG_VERSION}
ln -fs /usr/bin/clang ${PWD}/bin
ln -fs /usr/bin/scan-build ${PWD}/bin

# Setup prebuilt dependencies
echo "Setting up prebuilt dependencies from ${NEOVIM_DEPS_REPO}..."
sudo git clone --branch ${NEOVIM_DEPS_BRANCH} --depth 1 git://github.com/${NEOVIM_DEPS_REPO} ${NEOVIM_DEPS_DIR}
echo "eval \$(${NEOVIM_DEPS_DIR}/bin/luarocks path)" >> ${ENVIRONMENT_FILE}
echo "export PKG_CONFIG_PATH=\"${NEOVIM_DEPS_DIR}/lib/pkgconfig\"" >> ${ENVIRONMENT_FILE}
echo "export USE_BUNDLED_DEPS=OFF" >> ${ENVIRONMENT_FILE}
ln -fs ${NEOVIM_DEPS_DIR}/bin/* ${PWD}/bin

# Update PATH
echo "export PATH=\"${TRAVIS_BUILD_DIR}/deps/bin:\$PATH\"" >> ${ENVIRONMENT_FILE}
