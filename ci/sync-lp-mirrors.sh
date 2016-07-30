#!/usr/bin/env bash
set -e
set -o pipefail

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/dependencies.sh"

WORK_DIR=${WORK_DIR:-${BUILD_DIR}/build}
MIRROR_USER=${MIRROR_USER:-marvim}
MIRROR_BRANCH=${MIRROR_BRANCH:-master}

sync_lp_mirror() {
  local repo="${1}"
  local upstream_url="https://github.com/neovim/${repo}"
  local mirror_url="git+ssh://${MIRROR_USER}@git.launchpad.net/~neovim-ppa/neovim-ppa/+git/${repo}"
  local repo_dir="${WORK_DIR}/${repo}"

  echo "Cloning upstream repo ${upstream_url}."
  rm -rf "${repo_dir}"
  git clone --branch "${MIRROR_BRANCH}" "${upstream_url}" "${repo_dir}"

  echo "Pushing to ${mirror_url}."
  cd "${repo_dir}"
  git push "${mirror_url}" ${MIRROR_BRANCH}:${MIRROR_BRANCH}
}

clean_ssh_id() {
  shred -u "${SSH_KEY_FILE}"
}

setup_ssh_id() {
  export SSH_KEY_FILE="${BUILD_DIR}/ssh/id_rsa"
  if [[ ! -e "${SSH_KEY_FILE}" ]]; then
    # Private key encrypted by travis encrypt-file
    openssl aes-256-cbc -K ${encrypted_0b2795149c16_key} -iv ${encrypted_0b2795149c16_iv} \
      -in "${BUILD_DIR}/ssh/id_rsa.enc" -out "${SSH_KEY_FILE}" -d
    trap clean_ssh_id EXIT
  fi
  export GIT_SSH=${BUILD_DIR}/ssh/ssh_wrapper.sh
}

setup_ssh_id

sync_lp_mirror neovim
sync_lp_mirror deps
