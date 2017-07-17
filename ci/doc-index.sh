#!/usr/bin/env bash

set -e
set -u

readonly BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOC_INDEX_PAGE_URL="${DOC_INDEX_PAGE_URL:-https://neovim.io/doc_index}"
readonly DOC_SUBTREE='index.html'

source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/doc.sh"

generate_doc_index() {
  echo "Updating index.html from: ${DOC_INDEX_PAGE_URL}"
  curl -L --tlsv1 "${DOC_INDEX_PAGE_URL}" -o "${DOC_DIR}/${DOC_SUBTREE}"
}

main() {
  clone_doc
  generate_doc_index
  commit_doc
}

main
