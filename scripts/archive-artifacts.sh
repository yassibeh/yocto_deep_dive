#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DEST_DIR="${OUT_DIR}/${TIMESTAMP}"
mkdir -p "${DEST_DIR}"

if [ -d "${ST_DEPLOY_DIR}/images/${MACHINE}" ]; then
    mkdir -p "${DEST_DIR}/images"
    cp -a "${ST_DEPLOY_DIR}/images/${MACHINE}"/. "${DEST_DIR}/images/"
fi

if [ -d "${ST_BUILD_DIR}/tmp/log" ]; then
    mkdir -p "${DEST_DIR}/log"
    cp -a "${ST_BUILD_DIR}/tmp/log"/. "${DEST_DIR}/log/"
fi

if [ -f "${ST_BUILD_DIR}/conf/local.conf" ]; then
    cp -a "${ST_BUILD_DIR}/conf/local.conf" "${DEST_DIR}/"
fi

if [ -f "${ST_BUILD_DIR}/conf/bblayers.conf" ]; then
    cp -a "${ST_BUILD_DIR}/conf/bblayers.conf" "${DEST_DIR}/"
fi

if [ -f "${ST_BUILD_DIR}/conf/site.conf" ]; then
    cp -a "${ST_BUILD_DIR}/conf/site.conf" "${DEST_DIR}/"
fi

log "Artifacts copied to ${DEST_DIR}"
