#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd repo
require_cmd git
require_cmd python3

mkdir -p "${MANIFEST_DIR}"
cd "${MANIFEST_DIR}"

if [ ! -d .repo ]; then
    log "Initializing repo manifest ${ST_MANIFEST_TAG}"
    repo init -u "${ST_MANIFEST_URL}" -b "refs/tags/${ST_MANIFEST_TAG}"
else
    log "Repo workspace already initialized"
fi

log "Synchronizing manifest projects"
repo sync -c -j"$(nproc)"

log "Manifest workspace ready in ${MANIFEST_DIR}"
