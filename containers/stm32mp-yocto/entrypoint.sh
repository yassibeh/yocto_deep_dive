#!/usr/bin/env bash
set -euo pipefail

TARGET_UID="${LOCAL_UID:-1000}"
TARGET_GID="${LOCAL_GID:-1000}"
TARGET_USER="${LOCAL_USER:-builder}"
TARGET_GROUP="${LOCAL_GROUP:-builder}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
RUNTIME_USER="builder"
RUNTIME_GROUP="builder"

if ! getent group "${TARGET_GID}" >/dev/null 2>&1; then
    groupmod -g "${TARGET_GID}" "${RUNTIME_GROUP}"
else
    RUNTIME_GROUP="$(getent group "${TARGET_GID}" | cut -d: -f1)"
fi

if [ "${RUNTIME_GROUP}" != "builder" ]; then
    usermod -g "${TARGET_GID}" "${RUNTIME_USER}"
fi

usermod -u "${TARGET_UID}" "${RUNTIME_USER}"
usermod -d "/home/${RUNTIME_USER}" -m "${RUNTIME_USER}" >/dev/null 2>&1 || true

mkdir -p "${WORKSPACE_DIR}" "/home/${RUNTIME_USER}"
chown -R "${TARGET_UID}:${TARGET_GID}" "/home/${RUNTIME_USER}" "${WORKSPACE_DIR}" 2>/dev/null || true

export HOME="/home/${RUNTIME_USER}"
export USER="${TARGET_USER}"
export LOGNAME="${TARGET_USER}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su -s /bin/bash "${RUNTIME_USER}"
fi

exec su -s /bin/bash "${RUNTIME_USER}" -c "$*"
