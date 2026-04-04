#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

if [ ! -f "${BUILD_DIR}/conf/site.conf" ]; then
    echo "Missing ${BUILD_DIR}/conf/site.conf. Run environment setup first." >&2
    exit 1
fi

replace_or_append() {
    local key="$1"
    local value="$2"
    local file="$3"

    if grep -Eq "^[#[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i -E "s|^[#[:space:]]*${key}[[:space:]]*=.*|${key} = \"${value}\"|" "$file"
    else
        printf '%s = "%s"\n' "$key" "$value" >> "$file"
    fi
}

replace_or_append "DL_DIR" "${DL_DIR}" "${BUILD_DIR}/conf/site.conf"
replace_or_append "SSTATE_DIR" "${SSTATE_DIR}" "${BUILD_DIR}/conf/site.conf"

log "Configured site.conf to use direct shared cache paths"
