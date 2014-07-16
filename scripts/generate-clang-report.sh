generate_clang_report() {
  cd ${NEOVIM_DIR}

  # Generate static analysis report
  ${MAKE_CMD} deps
  mkdir -p build/clang-report
  scan-build \
    --use-analyzer=$(which clang) \
    --html-title="Neovim Static Analysis Report" \
    -o build/clang-report \
    ${MAKE_CMD}

  # Copy to doc repository
  rm -rf ${DOC_DIR}/build-reports/clang
  mkdir -p ${DOC_DIR}/build-reports/clang
  cp -r build/clang-report/*/* ${DOC_DIR}/build-reports/clang

  # Modify HTML to match Neovim's layout
  modify_clang_report
}

# Helper function to modify Clang report's index.html
# to use Neovim layout
modify_clang_report() {
  local index_file=${DOC_DIR}/build-reports/clang/index.html
  local script_file=${DOC_DIR}/build-reports/clang/clang-index.js

  # Move inline JavaScript to separate file
  extract_inline_script ${index_file} > ${script_file}

  # Remove colliding styles from scan-build's CSS
  local style_file=${DOC_DIR}/build-reports/clang/scanview.css
  sed -i -e '/^body/d' ${style_file} \
    -e '/^h1/d' ${style_file} \
    -e '/^h2/d' ${style_file} \
    -e '/^table {/d' ${style_file}

  # Wrap index.html's body with template
  local title="$(extract_title ${index_file})"
  local body="$(extract_body ${index_file})"
  generate_report "${title}" "${body}" "${index_file}"
}

# Helper function to extract HTML body
# ${1}:   Path to HTML file
# Output: HTML between opening and closing body tag
extract_body() {
  # 1. Extract between (and including) <body> tags
  # 2. Remove <body> tags
  # 3. Remove <h1> (title already in template)
  sed -n '/<body>/,/<\/body>/p' "${1}" \
    | sed -e '1d' -e '$d' \
    -e '/^<h1>/d'
}

# Helper function to extract HTML title
# ${1}:   Path to HTML file
# Output: Title of the HTML page
extract_title() {
  sed -rn 's/.*<title>(.*)<\/title>/\1/p' "${1}"
}

# Helper function to extract inline JavaScript from HTML head
# ${1}:   Path to HTML file
# Output: Inline JavaScript
extract_inline_script() {
  # 1. Extract between (and including) <script> tags
  # 2. Remove <script> tags
  sed -n '/<script language=.*>/,/<\/script>/p' "${1}" \
    | head -n -1 \
    | tail -n +2
}

