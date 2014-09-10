# Helper functions for reading and writing HTML.

# Generate a report from the ./templates/report.sh.html template.
# ${1}:   Report title
# ${2}:   Report body
# ${3}:   Path to HTML output file
# Output: None
generate_report() {
  require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable CI_TARGET "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_COMMIT "${BASH_SOURCE[0]}" ${LINENO}
  require_environment_variable NEOVIM_REPO "${BASH_SOURCE[0]}" ${LINENO}

  report_title="${1}" \
  report_body="${2}" \
  report_date=$(date -u) \
  report_commit="${NEOVIM_COMMIT}" \
  report_short_commit="${NEOVIM_COMMIT:0:7}" \
  report_repo="${NEOVIM_REPO}" \
  report_header=$([ -f ${BUILD_DIR}/templates/${CI_TARGET}/head.html ] && cat ${BUILD_DIR}/templates/${CI_TARGET}/head.html) \
  envsubst < "${BUILD_DIR}/templates/report.sh.html" > "${3}"
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
