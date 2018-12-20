#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/github-api.sh
source ${BUILD_DIR}/ci/common/neovim.sh

NIGHTLY_DIR=${NIGHTLY_DIR:-${BUILD_DIR}/build/nightly}
NIGHTLY_FILE=${NIGHTLY_FILE:-${BUILD_DIR}/build/nightly.tar.gz}
NVIM_BIN=${NIGHTLY_DIR}/nvim-${CI_OS}64/bin/nvim
NVIM_VERSION=unknown

build_nightly() {
  (
    require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

    mkdir -p ${NIGHTLY_DIR}

    cd ${NEOVIM_DIR}
    if [ "${CI_OS}" = osx ] ; then
      # This CMAKE_EXTRA_FLAGS is required for relocating the macOS libs.
      make CMAKE_BUILD_TYPE=Release \
           CMAKE_EXTRA_FLAGS="-DENABLE_JEMALLOC=OFF -DCMAKE_INSTALL_PREFIX:PATH= -DCMAKE_OSX_DEPLOYMENT_TARGET=10.11"
    else
      make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH="
    fi
    make DESTDIR="${NIGHTLY_DIR}/nvim-${CI_OS}64" install
  )
}

# Produces a "universal" Linux executable that looks like:
#     nvim-v0.2.1-26-gaea523a7ed5e.glibc2.17-x86_64.AppImage
# The executable, and the corresponding .zsync file, are placed into
# ${NEOVIM_DIR}/build/bin/.
build_appimage() {
  (
    require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

    sudo modprobe fuse

    sudo groupadd fuse
    sudo usermod -a -G fuse `whoami`

    cd ${NEOVIM_DIR}
    rm -rf build
    make appimage-nightly
    ls -lh build/bin/
  )
}

create_nightly_tarball() {
  (
    if [ "${CI_OS}" = osx ] ; then
        # Relocate the `nvim` dylib references.
        source ${BUILD_DIR}/ci/package-macos.sh "${NIGHTLY_DIR}/nvim-${CI_OS}64"
        # Overwrite the installed `nvim` with the new binary and its dylibs.
        cp -R bundle/nvim/bin   "${NIGHTLY_DIR}/nvim-${CI_OS}64/"
        cp -R bundle/nvim/libs  "${NIGHTLY_DIR}/nvim-${CI_OS}64/"
    fi

    cd ${NIGHTLY_DIR}
    tar cfz ${NIGHTLY_FILE} nvim-${CI_OS}64
  )
}

get_release_body() {
  echo 'Nvim development (pre-release) build.'
  echo '```'
  "${NVIM_BIN}" --version | head -n 3
  echo '```'
  echo '
## Install

### Windows

1. Extract [nvim-win64.zip](https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.zip) (or [nvim-win32.zip](https://github.com/neovim/neovim/releases/download/nightly/nvim-win32.zip))
2. Run: `nvim-qt.exe`

### macOS

1. Extract [nvim-macos.tar.gz](https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz)
2. Run: `./nvim-osx64/bin/nvim`

### Linux (x64)

1. Download [nvim.appimage](https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage)
2. Run: `chmod u+x nvim.appimage && ./nvim.appimage`
   - If your system does not have FUSE you can [extract the appimage](https://github.com/AppImage/AppImageKit/wiki/FUSE#type-2-appimage):
     ```
     ./nvim.appimage --appimage-extract
     ./squashfs-root/usr/bin/nvim
     ```

Or install by [package manager](https://github.com/neovim/neovim/wiki/Installing-Neovim).

Developers can [use this build in Travis CI](https://github.com/neovim/bot-ci#generated-builds).
'
}

get_nvim_version() {(
  set +e
  2>&1 "${NVIM_BIN}" --headless -u NONE +":echo (api_info().version.major).'.'.(api_info().version.minor).'.'.(api_info().version.patch)" +q
)}

upload_nightly() {
  require_args "$#" 4 "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_REPO "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_BRANCH "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_COMMIT "${BASH_SOURCE[0]}" ${LINENO}

  local delete_old="${1:-}"
  local tag="${2:-}"
  local filepath="${3:-}"
  local uploadname="${4:-}"
  echo "upload_nightly: delete_old=$delete_old tag=$tag filepath=$filepath uploadname=$uploadname"

  is_ci_build 'updating release page'
  if ! has_gh_token ; then
    return "$(can_fail_without_private)"
  fi

  local release_id
  read release_id < <( \
    send_gh_api_request repos/${NEOVIM_REPO}/releases \
    | jq -r -c "(.[] | select(.tag_name == \"${tag}\").id), \"\"") \
    || exit

  if [[ -z "${release_id}" ]]; then
    echo "Creating release for tag ${tag}."
    read release_id < <( \
      send_gh_api_data_request repos/${NEOVIM_REPO}/releases POST \
      "{ \"name\": \"NVIM ${NVIM_VERSION}-dev\", \"tag_name\": \"${tag}\", \
      \"prerelease\": true }" \
      | jq -r -c '.id') \
      || exit
  elif [ "$delete_old" = delete ] ; then
    echo "Deleting old release assets"
    local asset_id
    while read asset_id; do
      [[ -n "${asset_id}" ]] && \
        send_gh_api_request repos/${NEOVIM_REPO}/releases/assets/${asset_id} \
        DELETE \
        > /dev/null
    done < <( \
      send_gh_api_request repos/${NEOVIM_REPO}/releases/${release_id}/assets \
      | jq -r -c '.[].id') \
      || exit
  fi

  echo 'Updating release description.'
  # Set "draft" to un-publish. Then re-publish (to update the publish-date).
  send_gh_api_data_request repos/${NEOVIM_REPO}/releases/${release_id} PATCH \
    "{ \"draft\": true, \"body\": $(get_release_body | jq -s -c -R '.') }" \
    > /dev/null
  send_gh_api_data_request repos/${NEOVIM_REPO}/releases/${release_id} PATCH \
    "{ \"draft\": false, \"prerelease\": true }" \
    > /dev/null

  echo "Updating ${tag} tag to point to ${NEOVIM_COMMIT}."
  send_gh_api_data_request repos/${NEOVIM_REPO}/git/refs/tags/${tag} PATCH \
    "{ \"force\": true, \"sha\": \"${NEOVIM_COMMIT}\" }" \
    > /dev/null

  echo "Uploading asset: $uploadname"
  upload_release_asset "$filepath" "$uploadname" ${NEOVIM_REPO} ${release_id} \
    > /dev/null
}

has_current_nightly() {
  local nightly_commit
  read nightly_commit < <( \
    send_gh_api_request repos/${NEOVIM_REPO}/tags \
    | jq -r -c "(.[] | select(.name == \"${tag}\").commit.sha), \"\"") \
    || exit

  if [[ "${nightly_commit}" != "${NEOVIM_COMMIT}" ]]; then
    echo "tag '${tag}' does not point to ${NEOVIM_COMMIT}, continuing."
    return 1
  fi

  echo "tag '${tag}' already points to ${NEOVIM_COMMIT}, exiting."
}

get_appveyor_build() {(
  local type=$1
  local filepath=$2

  set +e
  curl -f -L 'https://ci.appveyor.com/api/projects/neovim/neovim/artifacts/build/Neovim.zip?branch=master&pr=false&job=Configuration%3A%20'"$type" -o "$filepath"
)}

clone_neovim

# Don't check this. We need to upload different builds to the same tag.
# has_current_nightly ||
{
  build_nightly
  NVIM_VERSION=$(get_nvim_version)
  if [ "${CI_OS}" = osx ] ; then
    create_nightly_tarball
    upload_nightly keep nightly "$NIGHTLY_FILE" "nvim-macos.tar.gz"
  else
    create_nightly_tarball
    upload_nightly delete nightly "$NIGHTLY_FILE" "nvim-${CI_OS}64.tar.gz"

    build_appimage
    upload_nightly keep nightly \
      "$(ls -1 ${NEOVIM_DIR}/build/bin/Neovim-*.AppImage | head -1)" \
      nvim.appimage
    upload_nightly keep nightly \
      "$(ls -1 ${NEOVIM_DIR}/build/bin/Neovim-*.AppImage.zsync | head -1)" \
      nvim.appimage.zsync

    get_appveyor_build MSVC_32 nvim-win32.zip
    [ -f nvim-win32.zip ] && upload_nightly keep nightly nvim-win32.zip nvim-win32.zip

    get_appveyor_build MSVC_64 nvim-win64.zip
    [ -f nvim-win64.zip ] && upload_nightly keep nightly nvim-win64.zip nvim-win64.zip
  fi
}
