# Helper functions for reading and writing HTML.

# Generate a report from the ./templates/report-*.sh.html templates.
# ${1}:   Report title
# ${2}:   Report body
# ${3}:   Path to HTML output file
# Output: None
generate_report() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable CI_TARGET "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_COMMIT "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_REPO "${BASH_SOURCE[0]}" ${LINENO}

  local head_file="${BUILD_DIR}/templates/${CI_TARGET}/head.html"
  local report_body="${2}"
  local output_file="${3}"

  echo "Applying Neovim layout for ${output_file}."

  # Write report header
  report_title="${1}" \
  report_head=$([[ -f ${head_file} ]] && cat ${head_file}) \
  envsubst < "${BUILD_DIR}/templates/report-header.sh.html" > "${output_file}"

  # Write report body
  echo "${report_body}" >> "${output_file}"

  # Write report footer
  report_commit="${NEOVIM_COMMIT}" \
  report_short_commit="${NEOVIM_COMMIT:0:7}" \
  report_repo="${NEOVIM_REPO}" \
  report_date=$(date -u) \
  envsubst < "${BUILD_DIR}/templates/report-footer.sh.html" >> "${output_file}"
}

# Extract body from HTML file.
# ${1}:   Path to HTML file
# Output: HTML between opening and closing body tag
extract_body() {
  # 1. Extract between (and including) <body> tags
  # 2. Remove <body> tags
  # 3. Remove <h1> (title already in template)
  sed -n '/<body/I,/<\/body>/Ip' "${1}" \
    | sed -e '1d' -e '$d' \
    -e '/^<h1>/Id'
}

# Extract page title from HTML file.
# ${1}:   Path to HTML file
# Output: Title of the HTML page
extract_title() {
  sed -rn 's/.*<title>(.*)<\/title>/\1/Ip' "${1}"
}

# Extract inline JavaScript from HTML file.
# ${1}:   Path to HTML file
# Output: Inline JavaScript
extract_inline_script() {
  # 1. Extract between (and including) <script> tags
  # 2. Remove <script> tags
  sed -n '/<script language=.*>/I,/<\/script>/Ip' "${1}" \
    | head -n -1 \
    | tail -n +2
}
