DOC_SUBTREE="/build-reports/vimpatch/"

generate_vimpatch_report() {
  # http://stedolan.github.io/jq/
  sudo apt-get install -y -q jq

  rm -rf ${DOC_DIR}/build-reports/vimpatch
  mkdir -p ${DOC_DIR}/build-reports/vimpatch

  generate_report "vim-patch report" "$(get_vimpatch_report_body)" \
    ${DOC_DIR}/build-reports/vimpatch/index.html
}

get_vimpatch_report_body() {
  get_open_pullrequests
  get_version_c
}

# Decorates a list of numbers as links to Vim's online repo.
linkify_numbers() {
  # zero-pad numbers less than 3 digits
  awk -F: '{ printf("%03d\n", $1) }' |
  sed 's/[0-9]*/<a href="https:\/\/code.google.com\/p\/vim\/source\/detail?r=v7-4-\0">vim-patch:7.4.\0<\/a><br>/'
}

# Generate HTML report from src/nvim/version.c
#   - merged patches:   listed in version.c
#   - unmerged patches: commented-out in version.c
#   - N/A patches:      commented-out with "//123 NA"
get_version_c() {
  local patches=$(sed -n '/static int included_patches/,/}/p' ${NEOVIM_DIR}/src/nvim/version.c |
                  grep -e '[0-9]' | sed 's/[ ,]//g' | grep -ve '^00*$')

  merged=$(echo "$patches" | grep -v \/\/ | linkify_numbers) \
  not_merged=$(echo "$patches" | grep \/\/ | grep -v NA | sed 's/\/\///g' | linkify_numbers) \
  not_applicable=$(echo "$patches" | grep -e '\/\/.*NA' | sed 's/\/\/\|NA//g' | linkify_numbers) \
  envsubst < ${BUILD_DIR}/templates/vimpatch-report/body.sh.html
}

# Generate HTML report of the current 'vim-patch' pull requests on GitHub
get_open_pullrequests() {
  echo "<div class=\"col\"><h2>Pull requests</h2>"

  curl 'https://api.github.com/repos/neovim/neovim/pulls?state=open&per_page=100' 2>/dev/null |
  jq '[.[] | {html_url, title} |  select(contains({title: "vim-patch"}))] | sort_by(.title) | map("<a href=\"\(.html_url)\">\(.title)</a><br/>")' |
  # use sed until travis gets jq 1.3+ (has 'reduce' and '@html')
  sed 's/^  "//' |
  sed 's/\("\|",\)$//' |
  sed 's/^\[//' |
  sed 's/^\]//' |
  sed 's/\\"/"/g'

  echo "</div>"
}
