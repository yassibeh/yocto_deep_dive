#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
RUNTIME_USER="yocto"
RUNTIME_HOME="/home/${RUNTIME_USER}"

mkdir -p "${WORKSPACE_DIR}" "${RUNTIME_HOME}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su - "${RUNTIME_USER}"
fi

exec su - "${RUNTIME_USER}" -c "cd '${WORKSPACE_DIR}' && $*"
