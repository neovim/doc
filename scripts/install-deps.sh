#!/bin/bash -e

# Install necessary dependencies for scripts/publish-docs.sh
# on Travis CI.
#
# Required environment variables:
# ${TRAVIS_BUILD_DIR}

install_deps() {
  local doxygen_version=1.8.7
  local clang_version=3.4
  local neovim_deps_repo=neovim/deps
  local neovim_deps_branch=master
  local neovim_deps_dir=/opt/neovim-deps

  local bin_dir=${TRAVIS_BUILD_DIR}/deps/bin

  mkdir -p ${bin_dir}
  cd ${TRAVIS_BUILD_DIR}/deps

  # Install doxygen
  echo "Installing Doxygen ${doxygen_version}..."
  mkdir -p doxygen
  wget -q -O - http://ftp.stack.nl/pub/users/dimitri/doxygen-${doxygen_version}.linux.bin.tar.gz \
    | tar xzf - --strip-components=1 -C doxygen
  ln -fs ${PWD}/doxygen/bin/doxygen ${bin_dir}

  # Install scan-build from PPA
  echo "Installing Clang ${clang_version}..."
  sudo add-apt-repository 'deb http://llvm.org/apt/precise/ llvm-toolchain-precise main'
  wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
  sudo apt-get update -qq
  sudo apt-get install -y -q clang-${clang_version}
  ln -fs /usr/bin/clang ${bin_dir}
  ln -fs /usr/bin/scan-build ${bin_dir}

  # Setup prebuilt dependencies
  echo "Setting up prebuilt dependencies from ${neovim_deps_repo}..."
  sudo git clone --branch ${neovim_deps_branch} --depth 1 git://github.com/${neovim_deps_repo} ${neovim_deps_dir}
  eval $(${neovim_deps_dir}/bin/luarocks path)
  export PKG_CONFIG_PATH="${neovim_deps_dir}/lib/pkgconfig"
  export USE_BUNDLED_DEPS=OFF
  ln -fs ${neovim_deps_dir}/bin/* ${bin_dir}

  # Update PATH
  export PATH="${bin_dir}:${PATH}"
}
