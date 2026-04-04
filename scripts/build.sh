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

"${SCRIPT_DIR}/prepare-build-dir.sh"

log "Preparing OpenSTLinux environment"
TARGET_DISTRO="${DISTRO}"
TARGET_MACHINE="${MACHINE}"
TARGET_IMAGE="${YOCTO_IMAGE}"
if [ "${ST_AUTO_ACCEPT_EULA}" = "1" ]; then
    TARGET_EULA_VAR="EULA_$(printf '%s' "${TARGET_MACHINE}" | sed 's/-//g; s/\.//g')"
    export "${TARGET_EULA_VAR}=1"
fi
export DISTRO MACHINE BB_NUMBER_THREADS PARALLEL_MAKE FORCE_DL_CACHEPREFIX FORCE_SSTATE_CACHEPREFIX
set +u
# shellcheck disable=SC1091
source layers/meta-st/scripts/envsetup.sh "${BUILD_DIR_NAME}" >/dev/null
set -u

"${SCRIPT_DIR}/configure-cache-paths.sh"
"${SCRIPT_DIR}/configure-bblayers.sh"

require_cmd bitbake

append_if_missing() {
    local line="$1"
    local file="$2"
    grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

append_if_missing "BB_NUMBER_THREADS = \"${BB_NUMBER_THREADS}\"" "${BUILDDIR}/conf/local.conf"
append_if_missing "PARALLEL_MAKE = \"${PARALLEL_MAKE}\"" "${BUILDDIR}/conf/local.conf"

log "Starting bitbake ${TARGET_IMAGE} for ${TARGET_MACHINE}"
bitbake "${TARGET_IMAGE}"

log "Build finished"
