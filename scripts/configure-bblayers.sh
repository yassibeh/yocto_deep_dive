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

    if grep -Fq "${layer_path}" "${BBLAYERS_CONF}"; then
        return 0
    fi

    python3 - "$BBLAYERS_CONF" "$layer_path" <<'PY'
import sys
from pathlib import Path

conf_path = Path(sys.argv[1])
layer = sys.argv[2]
text = conf_path.read_text()
needle = 'BASELAYERS ?= " \\\n'
insert = f'{needle}    {layer} \\\n'

if layer in text:
    sys.exit(0)

if needle not in text:
    raise SystemExit(f'Could not find BASELAYERS block in {conf_path}')

text = text.replace(needle, insert, 1)
conf_path.write_text(text)
PY
}

append_layer_if_missing '${OEROOT}/layers/meta-openembedded/meta-oe'
append_layer_if_missing '${OEROOT}/layers/meta-openembedded/meta-python'

log "Configured bblayers.conf with required meta-openembedded dependency layers"
