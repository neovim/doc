#!/bin/bash -e

# Install necessary dependencies for scripts/publish-docs.sh
# on Travis CI.

DOXYGEN_VERSION=1.8.7
CLANG_VERSION=3.4

mkdir -p ${TRAVIS_BUILD_DIR}/deps/bin
cd ${TRAVIS_BUILD_DIR}/deps

# Install doxygen
wget http://ftp.stack.nl/pub/users/dimitri/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz
mkdir -p doxygen
tar -xzf doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz -C doxygen --strip-components=1
ln -fs ${PWD}/doxygen/bin/doxygen ${PWD}/bin

# Install scan-build from PPA
sudo add-apt-repository 'deb http://llvm.org/apt/precise/ llvm-toolchain-precise main'
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install -y clang-${CLANG_VERSION}
ln -fs /usr/bin/clang ${PWD}/bin
ln -fs /usr/bin/scan-build ${PWD}/bin
