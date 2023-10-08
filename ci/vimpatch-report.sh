#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BUILD_DIR
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/html.sh

generate_vimpatch_report() {
  rm -rf ${DOC_DIR}/reports/vimpatch
  mkdir -p ${DOC_DIR}/reports/vimpatch

  body=$(get_vimpatch_report_body)
  generate_report "Vim Patch Report" "${body}" \
    ${DOC_DIR}/reports/vimpatch/index.html
}

get_vimpatch_report_body() {
  python3 "${BUILD_DIR}/ci/vimpatch-report.py"
}

DOC_SUBTREE="/reports/vimpatch/"
generate_vimpatch_report
