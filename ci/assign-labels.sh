#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BUILD_DIR}/ci/common/common.sh"
source "${BUILD_DIR}/ci/common/dependencies.sh"
source "${BUILD_DIR}/ci/common/github-api.sh"
source "${BUILD_DIR}/ci/common/neovim.sh"

TAGS=('[WIP]' '[RFC]' '[RDY]' 'vim-patch')
LABELS=('WIP' 'RFC' 'RDY' 'vim-patch')
DRY_RUN=${DRY_RUN:-false}

is_label_exclusive() {
  local label="${1}"
  for ((i=0; i < ${#LABELS[@]}; i=i+1)); do
    # Only the first 3 tags/labels (WIP/RFC/RDY) are mutually-exclusive.
    [ "$i" -gt 2 ] && return 1
    [ "${label}" = "${LABELS[i]}" ] && return 0
  done
  return 1
}

label_issue() {
  local issue_id="${1}"
  local issue_labels="${2}"
  local new_label="${3}"

  # Update existing labels or create the first one.
  if [ -n "${issue_labels}" ]; then
    issue_labels="\"${issue_labels//,/\",\"}\","

    # Remove existing mutually-exclusive labels, if any.
    if is_label_exclusive "$new_label"; then
      for label in "${LABELS[@]}"; do
        local old_label="${label}"
        if is_label_exclusive "$old_label" \
            && [[ "${issue_labels}" == *"${old_label}"* && "${old_label}" != "${new_label}" ]]; then
          echo "  Removing '${old_label}' label (it is mutually-exclusive with '${new_label}')."
          issue_labels="${issue_labels/\"${old_label}\",/}"
        fi
      done
    fi
    # Append new label to existing ones.
    issue_labels="${issue_labels}\"${new_label}\""
  else
    issue_labels="\"${new_label}\""
  fi

  if [[ ${DRY_RUN} != true ]]; then
    send_gh_api_data_request "repos/${NEOVIM_REPO}/issues/${issue_id}" \
      PATCH \
      "{\"labels\": [${issue_labels}]}" \
      > /dev/null
  fi
}

check_issue() {
  local issue_id="${1}"
  local issue_name="${2}"
  local issue_labels="${3}"


  # Check if issue title contains any of the tag strings.
  local i
  for ((i=0; i < ${#TAGS[@]}; i=i+1)); do
    local tag="${TAGS[i]}"
    local new_label="${LABELS[i]}"

    if echo "${issue_name}" | >/dev/null 2>&1 grep -F "${tag}" ; then
      echo "PR title '${issue_name}' contains '${tag}'"

      # Check if issue is already labelled correctly.
      if ! echo "${issue_labels}" | >/dev/null 2>&1 grep -F "${new_label}" ; then
        echo "Updating ${tag} issue ${issue_id}."
        echo "  Adding '${new_label}' label."
        label_issue "${issue_id}" "${issue_labels}" "${new_label}"
      else
        echo "issue ${issue_id} already labeled '${new_label}'"
      fi
    fi
  done
}

assign_labels() {
  local page
  for ((page=1; ; page=page+1)); do
    local issues
    echo "page $page..."

    readarray -t issues < <( \
      send_gh_api_request "repos/${NEOVIM_REPO}/pulls?sort=updated&direction=desc&per_page=100&page=${page}" \
      | jq -r -c 'map(select(.id?)) | .[] | .number, .title, (.labels | map(.name) | join(","))') \
      || exit

    # Abort if no more issues returned from API.
    if [[ -z "${issues[*]}" ]]; then
      break
    fi

    local i
    for ((i=0; i < ${#issues[@]}; i=i+3)); do
      check_issue "${issues[i]}" "${issues[i+1]}" "${issues[i+2]}"
    done
  done
}

assign_labels
