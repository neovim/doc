#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/github-api.sh
source ${BUILD_DIR}/ci/common/neovim.sh

NIGHTLY_DIR=${NIGHTLY_DIR:-${BUILD_DIR}/build/nightly}
NIGHTLY_FILE=${NIGHTLY_FILE:-${BUILD_DIR}/build/nightly.tar.gz}
NIGHTLY_TAG=${NIGHTLY_RELEASE:-nightly}
NVIM_BIN=${NIGHTLY_DIR}/nvim-${CI_OS}64/bin/nvim
NVIM_VERSION=unknown

build_nightly() {(
  require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

  mkdir -p ${NIGHTLY_DIR}

  cd ${NEOVIM_DIR}
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DENABLE_JEMALLOC=OFF -DCMAKE_INSTALL_PREFIX:PATH="
  make DESTDIR="${NIGHTLY_DIR}/nvim-${CI_OS}64" install
)}

create_nightly_tarball() {(
  if [ "${CI_OS}" = osx ] ; then
    # Relocate the `nvim` dylib references.
    source ${BUILD_DIR}/ci/package-macos.sh "${NIGHTLY_DIR}/nvim-${CI_OS}64"
    # Overwrite the installed `nvim` with the new binary and its dylibs.
    cp -R bundle/nvim/bin   "${NIGHTLY_DIR}/nvim-${CI_OS}64/"
    cp -R bundle/nvim/libs  "${NIGHTLY_DIR}/nvim-${CI_OS}64/"
  fi

  cd ${NIGHTLY_DIR}
  tar cfz ${NIGHTLY_FILE} nvim-${CI_OS}64
)}

get_release_body() {
  echo 'Nvim development (pre-release) build. See **[Installing-Neovim](https://github.com/neovim/neovim/wiki/Installing-Neovim)**.'
  echo
  echo 'Developers: see the [`bot-ci` README](https://github.com/neovim/bot-ci#generated-builds) to use this build automatically on Travis CI.'
  echo
  echo '```'
  "${NVIM_BIN}" --version
  echo '```'
}

get_nvim_version() {
  echo $( set +e ; 2>&1 "${NVIM_BIN}" --headless -u NONE +":echo (api_info().version.major).'.'.(api_info().version.minor).'.'.(api_info().version.patch)" +q )
}

upload_nightly() {
  if test -z "$GH_TOKEN" ; then
    return $(can_fail_without_private)
  fi

  require_environment_variable NEOVIM_REPO "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_BRANCH "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_COMMIT "${BASH_SOURCE[0]}" ${LINENO}

  local delete_old=$1

  local release_id
  read release_id < <( \
    send_gh_api_request repos/${NEOVIM_REPO}/releases \
    | jq -r -c "(.[] | select(.tag_name == \"${NIGHTLY_TAG}\").id), \"\"") \
    || exit

  if [[ -z "${release_id}" ]]; then
    echo "Creating release for tag ${NIGHTLY_TAG}."
    read release_id < <( \
      send_gh_api_data_request repos/${NEOVIM_REPO}/releases POST \
      "{ \"name\": \"NVIM v${NVIM_VERSION}-dev\", \"tag_name\": \"${NIGHTLY_TAG}\", \
      \"prerelease\": true }" \
      | jq -r -c '.id') \
      || exit
  elif [ "$delete_old" = delete ] ; then
    echo 'Deleting old nightly tarballs.'
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
  send_gh_api_data_request repos/${NEOVIM_REPO}/releases/${release_id} PATCH \
    "{ \"body\": $(get_release_body | jq -s -c -R '.') }" \
    > /dev/null

  echo "Updating ${NIGHTLY_TAG} tag to point to ${NEOVIM_COMMIT}."
  send_gh_api_data_request repos/${NEOVIM_REPO}/git/refs/tags/${NIGHTLY_TAG} PATCH \
    "{ \"force\": true, \"sha\": \"${NEOVIM_COMMIT}\" }" \
    > /dev/null

  echo 'Uploading package.'
  local name="nvim-${CI_OS}64.tar.gz"
  [ "${CI_OS}" = osx ] && name="nvim-macos.tar.gz"
  upload_release_asset ${NIGHTLY_FILE} "$name" \
    ${NEOVIM_REPO} ${release_id} \
    > /dev/null
}

has_current_nightly() {
  local nightly_commit
  read nightly_commit < <( \
    send_gh_api_request repos/${NEOVIM_REPO}/tags \
    | jq -r -c "(.[] | select(.name == \"${NIGHTLY_TAG}\").commit.sha), \"\"") \
    || exit

  if [[ "${nightly_commit}" != "${NEOVIM_COMMIT}" ]]; then
    echo "${NIGHTLY_TAG} tag does not point to ${NEOVIM_COMMIT}, continuing."
    return 1
  fi

  echo "${NIGHTLY_TAG} tag already points to ${NEOVIM_COMMIT}, exiting."
}

clone_neovim

# Don't check this. We need to upload different builds to the same tag.
# has_current_nightly ||
{
  build_nightly
  NVIM_VERSION=$(get_nvim_version)
  create_nightly_tarball
  [ "${CI_OS}" = osx ] && upload_nightly || upload_nightly delete
}
