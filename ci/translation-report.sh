#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/deps-repo.sh
source ${BUILD_DIR}/ci/common/doc.sh
source ${BUILD_DIR}/ci/common/neovim.sh
source ${BUILD_DIR}/ci/common/html.sh

generate_translation_report() {
  cd ${NEOVIM_DIR}

  # Generate CMake files
  ${MAKE_CMD} cmake

  # Update .po & generate .mo files
  cd build
  ${MAKE_CMD} update-po
  ${MAKE_CMD} translations

  # Rebuild the translation report
  rm -rf ${DOC_DIR}/reports/translations
  mkdir -p ${DOC_DIR}/reports/translations
  generate_report "Neovim Translation Report" "$(get_translation_report_body)" \
    ${DOC_DIR}/reports/translations/index.html
}

# Helper function for translation report
get_translation_report_body() {
  local regex="(([0-9]+) translated messages)?(, ([0-9]+) fuzzy translations)?(, ([0-9]+) untranslated messages)?."

  # Generate stats for each language
  cd ${NEOVIM_DIR}/build
  for mo_file in src/nvim/po/*.mo; do
    local filename=$(basename ${mo_file})
    local language_name="${filename%.mo}"

    # Only list language once (use e.g. ko, not ko.UTF-8)
    if [[ ${language_name} == *.* ]]; then
      continue
    fi

    # Run PO checks & get warnings
    make check-po-${language_name} >/dev/null 2>&1 || true
    local warnings=$(head -n -2 src/nvim/po/check-${language_name}.log | tail -n +2)
    # Each warning is printed on 3 lines
    local warnings_count=$(($(echo "${warnings}" | wc -l)/3))

    # Extract language statistics
    local language_stats=$(OLD_PO_FILE_INPUT=yes msgfmt -v -o src/nvim/po/${language_name}.mo ../src/nvim/po/${language_name}.po 2>&1)
    [[ ${language_stats} =~ ${regex} ]]

    # Echo number of translated, fuzzy, untranslated messages
    translated=${BASH_REMATCH[2]:-0} \
    fuzzy=${BASH_REMATCH[4]:-0} \
    untranslated=${BASH_REMATCH[6]:-0} \
    messages=$((${translated}+${fuzzy}+${untranslated})) \
    translated_width=$(((${translated}*100+${messages}/2)/${messages})) \
    fuzzy_width=$((${translated_width}+(${fuzzy}*100+${messages}/2)/${messages})) \
    language_name=${language_name} \
    envsubst < ${BUILD_DIR}/templates/translation-report/stats.sh.html

    # Echo warnings (if any)
    if [[ ${warnings_count} -eq 0 ]]; then
      envsubst < ${BUILD_DIR}/templates/translation-report/no-warnings.sh.html
    else
      warnings=${warnings} \
      warnings_count=${warnings_count} \
      language_name=${language_name} \
      envsubst < ${BUILD_DIR}/templates/translation-report/warnings.sh.html
    fi
  done
}

DOC_SUBTREE="/reports/translations/"
clone_doc
clone_neovim
generate_translation_report
commit_doc
