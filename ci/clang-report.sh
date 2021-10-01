#!/usr/bin/env bash
set -e
set -o pipefail

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BUILD_DIR/ci/common/common.sh"
source "$BUILD_DIR/ci/common/doc.sh"
source "$BUILD_DIR/ci/common/html.sh"
source "$BUILD_DIR/ci/common/badge.sh"

generate_clang_report() {
  cd ${NEOVIM_DIR}

  mkdir -p build/clang-report

  # Compile deps
  ${MAKE_CMD} deps

  # Generate report
  if "${SCAN_BUILD:-scan-build}" \
      --status-bugs \
      --html-title="Neovim Static Analysis" \
      --exclude "src/cjson/" \
      --exclude "src/mpack/" \
      --exclude "src/xdiff/" \
      -o build/clang-report \
      ${MAKE_CMD} \
      | tee ${BUILD_DIR}/scan-build.out
  then
    scan_build_result=no-warnings
  else
    scan_build_result=warnings
  fi

  # Copy to doc repository
  rm -rf ${DOC_DIR}/reports/clang
  mkdir -p ${DOC_DIR}/reports/clang

  # If clang reported warnings, copy report pages.
  # Otherwise use a blank page.
  if [[ "$scan_build_result" == "warnings" ]]; then
    cp -r build/clang-report/*/* ${DOC_DIR}/reports/clang

    # Modify HTML to match Neovim's layout
    modify_clang_report
  else
    generate_report "Neovim Static Analysis Report" \
      "$(< ${BUILD_DIR}/templates/clang-report/no-warnings.html)" \
      ${DOC_DIR}/reports/clang/index.html
  fi
}

# Helper function to modify Clang report's index.html
# to use Neovim layout
modify_clang_report() {
  local index_file=${DOC_DIR}/reports/clang/index.html
  local script_file=${DOC_DIR}/reports/clang/clang-index.js

  # Move inline JavaScript to separate file
  extract_inline_script ${index_file} > ${script_file}

  # Remove colliding styles from scan-build's CSS
  local style_file=${DOC_DIR}/reports/clang/scanview.css
  sed -i -e '/^body/d' ${style_file} \
    -e '/^h1/d' ${style_file} \
    -e '/^h2/d' ${style_file} \
    -e '/^table {/d' ${style_file}

  # Wrap index.html's body with template
  local title="$(extract_title ${index_file})"
  local body="$(extract_body ${index_file})"
  generate_report "${title}" "${body}" "${index_file}"
}

# Helper function to download clang analyzer badge from shields.io
download_clang_badge() {
  download_badge \
    "$(find_all_bugs_number "$BUILD_DIR/scan-build.out")" \
    "clang_analysis" \
    "$DOC_DIR/$DOC_SUBTREE"
}

# Helper function to find number of all bugs in build-scan output
# ${1}:   Path to scan-build output file
# Output: Number of all found bugs
find_all_bugs_number() {
  # 1. Extract count from line "scan-build: * bugs found".
  # 2. Substitute "No" by 0
  sed -n 's/scan-build: \(.*\) bugs\{0,1\} found./\1/p' ${1} \
    | sed 's/No/0/'
}

DOC_SUBTREE="/reports/clang"
generate_clang_report
download_clang_badge
