#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/github-api.sh
source ${BUILD_DIR}/ci/common/neovim.sh

TAGS=('[WIP]' '[RFC]' '[RDY]')
LABELS=('WIP' 'RFC' 'RDY')
DRY_RUN=${DRY_RUN:-false}

label_issue() {
  local issue_id="${1}"
  local issue_labels="${2}"
  local new_label="${3}"

  # Modify existing labels, if any.
  # Otherwise just use new label.
  if [[ -n "${issue_labels}" ]]; then
    issue_labels="\"${issue_labels//,/\",\"}\","

    # Remove inapplicable labels, if any.
    local i
    for ((i=0; i < ${#LABELS[@]}; i=i+1)); do
      local old_label="${LABELS[i]}"

      if [[ "${issue_labels}" == *"${old_label}"* && "${old_label}" != "${new_label}" ]]; then
        echo "  Removing '${old_label}' label."
        issue_labels="${issue_labels/\"${old_label}\",/}"
      fi
    done
    # Append new label to existing ones.
    issue_labels="${issue_labels}\"${new_label}\""
  else
    issue_labels="\"${new_label}\""
  fi

  if [[ ${DRY_RUN} != true ]]; then
    send_gh_api_data_request repos/${NEOVIM_REPO}/issues/${issue_id} \
      PATCH \
      "{\"labels\": [${issue_labels}]}" \
      > /dev/null
  fi
}

check_issue() {
  local issue_id="${1}"
  local issue_name="${2}"
  local issue_labels="${3}"

  # Check if issue title is prefixed with any of the tags.
  local i
  for ((i=0; i < ${#TAGS[@]}; i=i+1)); do
    local tag="${TAGS[i]}"
    local new_label="${LABELS[i]}"

    if [[ "${issue_name}" == "${tag}"* ]]; then
      # Check if issue is already labelled correctly.
      if [[ "${issue_labels}" != *"${new_label}"* ]]; then
        echo "Updating ${tag} issue ${issue_id}."
        echo "  Adding '${new_label}' label."

        label_issue "${issue_id}" "${issue_labels}" "${new_label}"
      fi
      break
    fi
  done
}

assign_labels() {
  local page
  for ((page=1; ; page=page+1)); do
    local issues
    readarray -t issues < <( \
      send_gh_api_request "repos/${NEOVIM_REPO}/issues?sort=created&per_page=100&page=${page}" \
      | jq -r -c 'map(select(.pull_request?)) | .[] | .number, .title, (.labels | map(.name) | join(","))') \
      || exit

    # Abort if no more issues returned from API.
    if [[ -z "${issues}" ]]; then
      break
    fi

    local i
    for ((i=0; i < ${#issues[@]}; i=i+3)); do
      check_issue "${issues[i]}" "${issues[i+1]}" "${issues[i+2]}"
    done
  done
}

is_ci_build && {
  install_jq
}

assign_labels
