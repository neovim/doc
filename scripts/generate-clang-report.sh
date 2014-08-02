generate_clang_report() {
  cd ${NEOVIM_DIR}

  # Generate static analysis report
  mkdir -p build/clang-report
  scan-build \
    --use-analyzer=$(which clang) \
    --html-title="Neovim Static Analysis Report" \
    -o build/clang-report \
    ${MAKE_CMD} > scan-build.out

  # Copy to doc repository
  rm -rf ${DOC_DIR}/build-reports/clang
  mkdir -p ${DOC_DIR}/build-reports/clang
  cp -r build/clang-report/*/* ${DOC_DIR}/build-reports/clang

  # Modify HTML to match Neovim's layout
  modify_clang_report

  # Download badge from shields.io
  download_badge
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

# Helper function to download badge from shields.io
download_badge() {
  local all_bugs_number="$(find_all_bugs_number scan-build.out)"
  local code_quality_color="$(get_code_quality_color ${all_bugs_number})"
  local badge="clang_analysis-${all_bugs_number}-${code_quality_color}"
  wget https://img.shields.io/badge/${badge}.svg \
    -O ${DOC_DIR}/build-reports/clang/badge.svg
}

# Helper function to find number of all bugs in build-scan output
# ${1}:   Path to scan-build output file
# Output: Number of all found bugs
find_all_bugs_number() {
  # 1. Extract count from line "scan-build: * bugs found".
  # 2. Substitute "No" by 0
  sed -n 's/scan-build: \(.*\) bugs found./\1/p' scan-build.out \
    | sed 's/No/0/'
}

# Helper function to get the code quality color based on number of bugs
# ${1}:   Number of all found bugs
# Output: The name of the color
get_code_quality_color() {
  max_bugs=100
  yellow_threshold=$(($max_bugs / 2))
  bugs=$(($1 < $max_bugs ? $1 : $max_bugs))
  if [[ $bugs -ge $yellow_threshold ]]; then
    red=255
    green=$((255 - 255 * ($bugs - $yellow_threshold) / $yellow_threshold))
  else
    red=$((255 * $bugs / $yellow_threshold))
    green=255
  fi
  blue=0
  printf "%.2x%.2x%.2x" $red $green $blue
}
