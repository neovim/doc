#!/usr/bin/env bash
set -e
set -o pipefail

shopt -s globstar

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/deps-repo.sh
source ${BUILD_DIR}/ci/common/doc.sh
source ${BUILD_DIR}/ci/common/neovim.sh
source ${BUILD_DIR}/ci/common/html.sh

DOC_SUBTREE="/reports/clint/"
ERRORS_FILE="$DOC_DIR/$DOC_SUBTREE/errors.json"

generate_clint_report() {
  cd ${NEOVIM_DIR}

  local index_file="$DOC_DIR/$DOC_SUBTREE/index.html"

  ./clint.py --record-errors="$ERRORS_FILE" \
    src/nvim/**/*.c src/nvim/**/*.h 2> "$index_file" || true

  local title="Clint.py errors list"
  local body="<pre>$(cat "$index_file")</pre>"
  generate_report "$title" "$body" "$index_file"
}

# Helper function to download clint badge from shields.io
download_clint_badge() {
  local errors_number="$(cat "$ERRORS_FILE" | wc -l)"
  local code_quality_color="$(get_code_quality_color ${errors_number})"
  local badge="clint-${errors_number}-${code_quality_color}"
  local response

  response=$( 2>&1 curl --tlsv1 http://img.shields.io/badge/${badge}.svg \
    > ${DOC_DIR}/$DOC_SUBTREE/badge.svg || true )
  [ -f ${DOC_DIR}/$DOC_SUBTREE/badge.svg ] \
    || echo "failed to download badge: $response"
}

# Helper function to get the code quality color based on number of clint errors
# ${1}:   Number of all found errors
# Output: The name of the color
get_code_quality_color() {
  if (( $1 )) ; then
    printf red
  else
    printf green
  fi
}

clone_doc
clone_neovim
generate_clint_report
download_clint_badge
commit_doc
