#!/usr/bin/env bash

set -e
set -u

readonly BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${BUILD_DIR}/ci/common/common.sh"

generate_doc_index() {
  echo "Updating doc/ from file-list.txt"
  wget -i "${BUILD_DIR}/ci/file-list.txt" --force-directories -nH --cut-dirs=1 -P "${DOC_DIR}"
}

main() {
  generate_doc_index
}

main
