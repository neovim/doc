#!/usr/bin/env bash
set -e
set -o pipefail
set -u
set -x

shopt -s failglob
shopt -s dotglob

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BUILD_DIR/ci/common/common.sh"
source "$BUILD_DIR/ci/common/dependencies.sh"
source "$BUILD_DIR/ci/common/deps-repo.sh"
source "$BUILD_DIR/ci/common/doc.sh"
source "$BUILD_DIR/ci/common/neovim.sh"
source "$BUILD_DIR/ci/common/html.sh"
source "$BUILD_DIR/ci/common/badge.sh"

DOC_SUBTREE="/reports/pvs"
REPORTS_DIR="$DOC_DIR/$DOC_SUBTREE"

download_pvs_badge() {
  download_badge \
    "$(cat "$REPORTS_DIR/PVS-studio.err" | grep '^./' | wc -l)" \
    "PVS_analysis" \
    "$REPORTS_DIR"
}

generate_pvs_report() {
  rm -rf "$REPORTS_DIR"
  mkdir -p "$REPORTS_DIR"

  local index_file="$REPORTS_DIR/index.html"

  (
    cd "$NEOVIM_DIR"

    sh ./scripts/pvscheck.sh --pvs detect --pvs-install .
    sh ./scripts/pvscheck.sh --deps --recheck .

    # Note: will also copy a binary log with *all* errors, including filtered
    # out. This is intentional.
    cp PVS-studio* "$REPORTS_DIR"
  )
  (
    cd "$REPORTS_DIR"

    local body="<pre>$(cat PVS-studio.err | html_escape)</pre>"

    local title="PVS-studio analysis results"

    generate_report "$title" "$body" "$index_file"
  )
}

clone_doc
clone_neovim
generate_pvs_report
download_pvs_badge
commit_doc
