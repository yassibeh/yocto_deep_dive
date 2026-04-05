#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Install STM32CubeProgrammer into a target root filesystem path.

Usage:
  ./scripts/install-stm32cubeprogrammer.sh --from-file <installer> [--dest /opt/st/STM32CubeProgrammer]
  ./scripts/install-stm32cubeprogrammer.sh --from-dir <unpacked-dir> [--dest /opt/st/STM32CubeProgrammer]

Supported inputs:
  --from-file  path to the official STM32CubeProgrammer Linux installer .zip/.tar.gz bundle
  --from-dir   path to an already unpacked STM32CubeProgrammer installation tree

Environment:
  STM32CUBEPROG_ACCEPT_LICENSE=1   required for non-interactive install from bundle

Notes:
  - This script intentionally does not download STM32CubeProgrammer from unofficial sources.
  - Use an official ST package obtained by your organization or by manual download from st.com.
EOF
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

require_cmd python3
require_cmd find
require_cmd tar
require_cmd unzip
require_cmd install

SRC_FILE=""
SRC_DIR=""
DEST_DIR="${STM32CUBE_PROGRAMMER_ROOT:-/opt/st/STM32CubeProgrammer}"
WORK_DIR=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --from-file)
            SRC_FILE="${2:?missing value for --from-file}"
            shift 2
            ;;
        --from-dir)
            SRC_DIR="${2:?missing value for --from-dir}"
            shift 2
            ;;
        --dest)
            DEST_DIR="${2:?missing value for --dest}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -n "${SRC_FILE}" ] && [ -n "${SRC_DIR}" ]; then
    echo "Use either --from-file or --from-dir, not both." >&2
    exit 1
fi

if [ -z "${SRC_FILE}" ] && [ -z "${SRC_DIR}" ]; then
    echo "One of --from-file or --from-dir is required." >&2
    usage >&2
    exit 1
fi

cleanup() {
    if [ -n "${WORK_DIR}" ] && [ -d "${WORK_DIR}" ]; then
        rm -rf "${WORK_DIR}"
    fi
}
trap cleanup EXIT

copy_install_tree() {
    local source_tree="$1"
    local src_bin

    src_bin="$(find "${source_tree}" -type f -name 'STM32_Programmer_CLI' | head -n1 || true)"
    if [ -z "${src_bin}" ]; then
        echo "Could not locate STM32_Programmer_CLI under ${source_tree}" >&2
        exit 1
    fi

    local source_root
    source_root="$(cd "$(dirname "${src_bin}")/.." && pwd)"

    rm -rf "${DEST_DIR}"
    mkdir -p "$(dirname "${DEST_DIR}")"
    cp -a "${source_root}" "${DEST_DIR}"

    rm -rf \
        "${DEST_DIR}/uninstaller" \
        "${DEST_DIR}/.installationinformation" \
        "${DEST_DIR}/.install4j" \
        "${DEST_DIR}/.install4j"* \
        "${DEST_DIR}/install.builder"
}

if [ -n "${SRC_DIR}" ]; then
    [ -d "${SRC_DIR}" ] || {
        echo "Missing directory: ${SRC_DIR}" >&2
        exit 1
    }
    copy_install_tree "${SRC_DIR}"
else
    [ -f "${SRC_FILE}" ] || {
        echo "Missing file: ${SRC_FILE}" >&2
        exit 1
    }
    [ "${STM32CUBEPROG_ACCEPT_LICENSE:-0}" = "1" ] || {
        echo "Set STM32CUBEPROG_ACCEPT_LICENSE=1 to confirm you are installing an official STM32CubeProgrammer package under its applicable license." >&2
        exit 1
    }

    WORK_DIR="$(mktemp -d)"

    case "${SRC_FILE}" in
        *.zip)
            unzip -q "${SRC_FILE}" -d "${WORK_DIR}/bundle"
            ;;
        *.tar.gz|*.tgz)
            mkdir -p "${WORK_DIR}/bundle"
            tar -xzf "${SRC_FILE}" -C "${WORK_DIR}/bundle"
            ;;
        *)
            echo "Unsupported bundle format: ${SRC_FILE}" >&2
            exit 1
            ;;
    esac

    installer="$(find "${WORK_DIR}/bundle" -type f \( -name 'SetupSTM32CubeProgrammer-*' -o -name 'setup.sh' -o -name '*.run' \) | head -n1 || true)"
    if [ -z "${installer}" ]; then
        echo "Could not locate a STM32CubeProgrammer Linux installer inside ${SRC_FILE}" >&2
        exit 1
    fi

    chmod +x "${installer}"
    mkdir -p "${WORK_DIR}/install-root"

    if "${installer}" --help >/dev/null 2>&1; then
        if ! "${installer}" --mode unattended --prefix "${WORK_DIR}/install-root" >/tmp/stm32cubeprog-install.log 2>&1; then
            cat /tmp/stm32cubeprog-install.log >&2 || true
            echo "Non-interactive installer execution failed." >&2
            exit 1
        fi
    else
        echo "Installer does not expose a non-interactive interface that this script can use reproducibly." >&2
        exit 1
    fi

    copy_install_tree "${WORK_DIR}/install-root"
fi

for tool in \
    STM32_Programmer_CLI \
    STM32MP_KeyGen_CLI \
    STM32_KeyGen_CLI \
    STM32MP_SigningTool_CLI \
    STM32_SigningTool_CLI \
    STM32TrustedPackageCreator \
    STM32TrustedPackageCreator_CLI
 do
    if [ -x "${DEST_DIR}/bin/${tool}" ]; then
        echo "installed: ${DEST_DIR}/bin/${tool}"
    fi
done
