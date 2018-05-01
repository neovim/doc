#!/usr/bin/env bash

set -e
set -o pipefail
set -u
set -x

shopt -s failglob
shopt -s dotglob

readonly BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BUILD_DIR/ci/common/common.sh"
source "$BUILD_DIR/ci/common/dependencies.sh"
source "$BUILD_DIR/ci/common/deps-repo.sh"
source "$BUILD_DIR/ci/common/doc.sh"
source "$BUILD_DIR/ci/common/neovim.sh"
source "$BUILD_DIR/ci/common/html.sh"
source "$BUILD_DIR/ci/common/badge.sh"

readonly DOC_SUBTREE='/reports/pvs'
readonly REPORTS_DIR="$DOC_DIR/$DOC_SUBTREE"

download_pvs_badge() {
  download_badge                                     \
    "$(grep -c '^./' "$REPORTS_DIR/PVS-studio.err")" \
    'PVS_analysis'                                   \
    "$REPORTS_DIR"
}

generate_pvs_report() {
  local -r index_file="$REPORTS_DIR/index.html"

  rm -rf "$REPORTS_DIR"
  mkdir -p "$REPORTS_DIR"

  (
    cd "$NEOVIM_DIR"

    sh ./scripts/pvscheck.sh --environment-cc --pvs detect --pvs-install .
    sh ./scripts/pvscheck.sh --environment-cc --deps --recheck .

    # Note: will also copy a binary log with *all* errors, including filtered
    # out. This is intentional.
    cp -r PVS-studio* "$REPORTS_DIR"
  )

  (
    cd "$REPORTS_DIR"

    local -r body="<pre>$(html_escape < PVS-studio.err)</pre>"
    local -r title='PVS-studio analysis results'

    generate_report "$title" "$body" "$index_file"
  )
}

main() {
  clone_doc
  clone_neovim
  generate_pvs_report
  download_pvs_badge
  commit_doc
}

main
