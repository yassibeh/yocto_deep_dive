#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd bash

if [ ! -d "${MANIFEST_DIR}/layers/meta-st/scripts" ]; then
    echo "Manifest workspace not initialized. Run ./scripts/bootstrap-manifest.sh first." >&2
    exit 1
fi

cd "${MANIFEST_DIR}"

log "Preparing OpenSTLinux environment"
export DISTRO MACHINE BB_NUMBER_THREADS PARALLEL_MAKE FORCE_DL_CACHEPREFIX FORCE_SSTATE_CACHEPREFIX
set +u
# shellcheck disable=SC1091
source layers/meta-st/scripts/envsetup.sh "${BUILD_DIR_NAME}" >/dev/null
set -u

"${SCRIPT_DIR}/configure-cache-paths.sh"

require_cmd bitbake

append_if_missing() {
    local line="$1"
    local file="$2"
    grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

append_if_missing "BB_NUMBER_THREADS = \"${BB_NUMBER_THREADS}\"" "${BUILDDIR}/conf/local.conf"
append_if_missing "PARALLEL_MAKE = \"${PARALLEL_MAKE}\"" "${BUILDDIR}/conf/local.conf"

log "Starting bitbake ${YOCTO_IMAGE} for ${MACHINE}"
bitbake "${YOCTO_IMAGE}"

log "Build finished"
