#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPT_NAME="${BASH_SOURCE[0]}"
BUILD_DIR="$1"
PKG_FILENAME="${2:-nvim-macos.tar.bz2}"
DOTAPP="${3-}"

{ [ -f bundle ] || [ -d bundle ] ; } && { echo "${SCRIPT_NAME}: error: 'bundle' already exists"; exit 1; }

bundle="bundle/nvim"
mkdir -p $bundle/libs

if [ -z "$DOTAPP" ] ; then
  # Structure the output in the "portable" convention:
  #    bin/nvim
  #    libs/
  #    share/
  mkdir -p $bundle/bin
  cp "${BUILD_DIR}/bin/nvim" $bundle/bin/nvim
else
  # Structure the output for .app (.bz2) packaging:
  #    nvim
  #    libs/
  cp "${BUILD_DIR}/bin/nvim" $bundle/nvim
fi

libs=($(otool -L "${BUILD_DIR}/bin/nvim" | sed 1d | sed -E -e 's|^[[:space:]]*||' -e 's| .*||'))
echo "${SCRIPT_NAME}: libs:"
for lib in "${libs[@]}" ; do
  if echo "$lib" | 2>&1 >/dev/null grep libSystem ; then
    echo "  [skipped] $lib"
  else
    echo "  $lib"
    relname="libs/${lib##*/}"
    cp -L "$lib" "$bundle/$relname"
    if [ -z "$DOTAPP" ] ; then
      install_name_tool -change "$lib" "@executable_path/../$relname" $bundle/bin/nvim
    else
      install_name_tool -change "$lib" "@executable_path/$relname" $bundle/nvim
    fi
  fi
done

tar cjSf "$PKG_FILENAME" -C bundle nvim
printf "\n${SCRIPT_NAME}: contents of ${PKG_FILENAME}:\n"
tar -tf "$PKG_FILENAME"
