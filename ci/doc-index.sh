#!/usr/bin/env bash

set -e
set -u

readonly BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/doc.sh"

generate_doc_index() {
  echo "Updating doc folder from file-list.txt"
  wget -i file-list.txt --force-directories -nH --cut-dirs=1 -P "${DOC_DIR}"
}

main() {
  generate_doc_index
}

main
