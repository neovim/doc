#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh

DOC_INDEX_PAGE_URL=${DOC_INDEX_PAGE_URL:-http://neovim.io/doc_index}

generate_doc_index() {
  echo "Updating index.html from ${DOC_INDEX_PAGE_URL}."
  wget -q ${DOC_INDEX_PAGE_URL} -O ${DOC_DIR}/index.html
}

DOC_SUBTREE="/index.html"
clone_doc
generate_doc_index
commit_doc
