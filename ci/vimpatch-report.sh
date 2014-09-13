#!/bin/bash -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/doc.sh
source ${BUILD_DIR}/ci/common/neovim.sh
source ${BUILD_DIR}/ci/common/html.sh

generate_vimpatch_report() {
  rm -rf ${DOC_DIR}/reports/vimpatch
  mkdir -p ${DOC_DIR}/reports/vimpatch

  generate_report "Vim Patch Report" "$(get_vimpatch_report_body)" \
    ${DOC_DIR}/reports/vimpatch/index.html
}

get_vimpatch_report_body() {
  # Get patch information from src/nvim/version.c
  #   - merged patches:   listed in version.c
  #   - unmerged patches: commented-out in version.c
  #   - N/A patches:      commented-out with "//123 NA"
  local patches=$(sed -n '/static int included_patches/,/}/p' ${NEOVIM_DIR}/src/nvim/version.c |
    grep -e '[0-9]' | sed 's/[ ,]//g' | grep -ve '^00*$')

  merged=$(echo "${patches}" | grep -v \/\/ | linkify_numbers) \
  not_merged=$(echo "${patches}" | grep \/\/ | grep -v NA | sed 's/\/\///g' | linkify_numbers) \
  not_applicable=$(echo "${patches}" | grep -e '\/\/.*NA' | sed 's/\/\/\|NA//g' | linkify_numbers) \
  pull_requests=$(get_open_pullrequests) \
  envsubst < ${BUILD_DIR}/templates/vimpatch-report/body.sh.html
}

# Decorates a list of numbers as links to Vim's online repo.
linkify_numbers() {
  # zero-pad numbers less than 3 digits
  awk -F: '{ printf("%03d\n", $1) }' |
  sed 's/[0-9]*/<li><a href="https:\/\/code.google.com\/p\/vim\/source\/detail?r=v7-4-\0">vim-patch:7.4.\0<\/a><\/li>/'
}

# Generate HTML report of the current 'vim-patch' pull requests on GitHub
get_open_pullrequests() {
  curl "https://api.github.com/repos/neovim/neovim/pulls?state=open&per_page=100" 2>/dev/null |
  jq '[.[] | {html_url, title} |  select(contains({title: "vim-patch"}))] | sort_by(.title) | map("<li><a href=\"\(.html_url)\">\(.title)</a></li>")' |
  # use sed until travis gets jq 1.3+ (has 'reduce' and '@html')
  sed 's/^  "//' |
  sed 's/\("\|",\)$//' |
  sed 's/^\[//' |
  sed 's/^\]//' |
  sed 's/\\"/"/g'
}

is_ci_build && {
  install_jq
}

DOC_SUBTREE="/reports/vimpatch/"
clone_doc
clone_neovim
generate_vimpatch_report
commit_doc
