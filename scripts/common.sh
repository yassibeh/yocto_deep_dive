#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/config/build.env"

mkdir -p "${OUT_DIR}" "${DL_DIR}" "${SSTATE_DIR}"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}
