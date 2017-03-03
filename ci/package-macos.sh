#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPT_NAME="$0"
BUILD_DIR="$1"
PKG_FILENAME="${2:-nvim-macos.tar.bz2}"

{ [ -f bundle ] || [ -d bundle ] ; } && { echo "${SCRIPT_NAME}: error: 'bundle' already exists"; exit 1; }
mkdir -p bundle/nvim/libs
bundle="bundle/nvim"
cp "${BUILD_DIR}/bin/nvim" $bundle/nvim

libs=($(otool -L "${BUILD_DIR}/bin/nvim" | sed 1d | sed -E -e 's|^[[:space:]]*||' -e 's| .*||'))
echo "${SCRIPT_NAME}: libs:"
for lib in "${libs[@]}" ; do
  echo "    $lib"
  relname="libs/${lib##*/}"
  cp -L "$lib" "$bundle/$relname"
  install_name_tool -change "$lib" "@executable_path/$relname" bundle/nvim/nvim
done

tar cjSf "$PKG_FILENAME" -C bundle nvim
printf "\n${SCRIPT_NAME}: contents of ${PKG_FILENAME}:\n"
tar -tf "$PKG_FILENAME"
