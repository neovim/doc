#!/usr/bin/env bash
set -e
set -o pipefail

shopt -s globstar

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BUILD_DIR/ci/common/common.sh"
source "$BUILD_DIR/ci/common/dependencies.sh"
source "$BUILD_DIR/ci/common/deps-repo.sh"
source "$BUILD_DIR/ci/common/doc.sh"
source "$BUILD_DIR/ci/common/neovim.sh"
source "$BUILD_DIR/ci/common/html.sh"
source "$BUILD_DIR/ci/common/badge.sh"

DOC_SUBTREE="/reports/clint"
REPORTS_DIR="$DOC_DIR/$DOC_SUBTREE"
ERRORS_FILE="$REPORTS_DIR/errors.json"
EXCLUDE_PAT='src/nvim/(testdir|xdiff)'

generate_clint_report() {
  require_environment_variable NEOVIM_COMMIT "${BASH_SOURCE[0]}" $LINENO

  cd "$NEOVIM_DIR"

  rm "$REPORTS_DIR"/*.json

  local errors_file="$REPORTS_DIR/errors.json"
  local index_file="$REPORTS_DIR/index.html"
  local sect_header="<div data-file=\"%s\" data-commit=\"$NEOVIM_COMMIT\" class=\"clint-report-one\"><pre>"
  local sect_footer="</pre></div>"

  : > "$errors_file"
  : > "$index_file"

  local errors_files=""

  for f in src/nvim/**/*.[ch] ; do
    if echo "$f" | >/dev/null 2>&1 grep -E "$EXCLUDE_PAT" ; then
      log_info "generate_clint_report: skipped: $f"
    else
      local suffix="${f#src/nvim/}"
      suffix="${suffix//[\/.]/-}"
      local separate_errors_file="$REPORTS_DIR/$suffix.json"
      printf "$sect_header\n" "$f" >> "$index_file"
      ./src/clint.py --record-errors="$separate_errors_file" "$f" \
        2>&1 | html_escape >> "$index_file" \
      || true
      echo "$sect_footer" >> "$index_file"
      cat "$separate_errors_file" >> "$errors_file"
      errors_files="$errors_files $separate_errors_file"
    fi
  done

  tar c $errors_files | gzip -9 > "$REPORTS_DIR/errors.tar.gz"

  local title="Clint.py errors list"
  local body="$(cat "$index_file")"
  generate_report "$title" "$body" "$index_file"
}

download_clint_badge() {
  download_badge \
    "$(cat "$ERRORS_FILE" | wc -l)" \
    "clint" \
    "$REPORTS_DIR" \
    40000
}

clone_doc
clone_neovim
generate_clint_report
download_clint_badge
commit_doc
