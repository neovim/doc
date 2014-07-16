#!/bin/bash -e

# Install necessary dependencies for scripts/publish-docs.sh
# on Travis CI.

DOXYGEN_VERSION=1.8.7
CLANG_VERSION=3.4

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
