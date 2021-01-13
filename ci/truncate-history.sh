#!/usr/bin/env bash
set -e
set -o pipefail

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BUILD_DIR/ci/common/common.sh"
source "$BUILD_DIR/ci/common/doc.sh"

try_truncate_history
