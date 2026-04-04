#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

BBLAYERS_CONF="${ST_BUILD_DIR}/conf/bblayers.conf"

if [ ! -f "${BBLAYERS_CONF}" ]; then
    echo "Missing ${BBLAYERS_CONF}. Run environment setup first." >&2
    exit 1
fi

append_layer_if_missing() {
    local layer_path="$1"
    local escaped_path
    escaped_path=$(printf '%s
' "$layer_path" | sed 's/[.[\*^$()+?{|]/\\&/g')

    if grep -Eq "${escaped_path}" "${BBLAYERS_CONF}"; then
        return 0
    fi

    awk -v layer="    ${layer_path} \\\" '
        /BASELAYERS \?= " \\/ && !done {
            print
            print layer
            done=1
            next
        }
        { print }
    ' "${BBLAYERS_CONF}" > "${BBLAYERS_CONF}.tmp"

    mv "${BBLAYERS_CONF}.tmp" "${BBLAYERS_CONF}"
}

append_layer_if_missing '${OEROOT}/layers/meta-openembedded/meta-oe'
append_layer_if_missing '${OEROOT}/layers/meta-openembedded/meta-python'

log "Configured bblayers.conf with required meta-openembedded dependency layers"
