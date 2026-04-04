#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

usage() {
    cat <<EOF
Usage:
  ./scripts/stm32cubeprogrammer.sh list-usb
  ./scripts/stm32cubeprogrammer.sh flash-layout <port> <flashlayout.tsv>
  ./scripts/stm32cubeprogrammer.sh flash-emmc <port> [flashlayout.tsv]

Defaults:
  flash-emmc uses:
    ${ST_DEPLOY_DIR}/images/${MACHINE}/FlashLayout_emmc_${MACHINE}_trusted.tsv

Environment overrides:
  STM32CUBEPROGRAMMER_CLI   path to STM32_Programmer_CLI
EOF
}

require_file() {
    local path="$1"
    [ -f "${path}" ] || {
        echo "Missing file: ${path}" >&2
        exit 1
    }
}

cmd="${1:-}"
case "${cmd}" in
    ""|-h|--help|help)
        usage
        exit 0
        ;;
esac

STM32CUBEPROGRAMMER_CLI="${STM32CUBEPROGRAMMER_CLI:-}"
if [ -z "${STM32CUBEPROGRAMMER_CLI}" ]; then
    for candidate in \
        /usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI \
        /opt/st/STM32CubeProgrammer/bin/STM32_Programmer_CLI \
        STM32_Programmer_CLI
    do
        if command -v "${candidate}" >/dev/null 2>&1; then
            STM32CUBEPROGRAMMER_CLI="$(command -v "${candidate}")"
            break
        fi
        if [ -x "${candidate}" ]; then
            STM32CUBEPROGRAMMER_CLI="${candidate}"
            break
        fi
    done
fi

if [ -z "${STM32CUBEPROGRAMMER_CLI}" ]; then
    cat >&2 <<'EOF'
STM32CubeProgrammer CLI not found.

Provide it explicitly, for example:
  export STM32CUBEPROGRAMMER_CLI=/usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI

This repository does not bundle STM32CubeProgrammer in the default build container.
Use a host installation or a separately mounted vendor-supplied installation.
EOF
    exit 1
fi

case "${cmd}" in
    list-usb)
        exec "${STM32CUBEPROGRAMMER_CLI}" -l USB
        ;;
    flash-layout)
        port="${2:?port is required}"
        flashlayout="${3:?flashlayout TSV path is required}"
        require_file "${flashlayout}"
        exec "${STM32CUBEPROGRAMMER_CLI}" -c "port=${port}" -w "${flashlayout}"
        ;;
    flash-emmc)
        port="${2:?port is required}"
        flashlayout="${3:-${ST_DEPLOY_DIR}/images/${MACHINE}/FlashLayout_emmc_${MACHINE}_trusted.tsv}"
        require_file "${flashlayout}"
        exec "${STM32CUBEPROGRAMMER_CLI}" -c "port=${port}" -w "${flashlayout}"
        ;;
    *)
        echo "Unknown command: ${cmd}" >&2
        usage >&2
        exit 1
        ;;
esac
