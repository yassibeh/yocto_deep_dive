#!/usr/bin/env bash
set -euo pipefail

TARGET_UID="${LOCAL_UID:-1000}"
TARGET_GID="${LOCAL_GID:-1000}"
TARGET_USER="${LOCAL_USER:-builder}"
TARGET_GROUP="${LOCAL_GROUP:-builder}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"

existing_group_name="$(getent group "${TARGET_GID}" | cut -d: -f1 || true)"
if [ -z "${existing_group_name}" ]; then
    groupmod -n "${TARGET_GROUP}" builder 2>/dev/null || groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
else
    TARGET_GROUP="${existing_group_name}"
fi

if id -u "${TARGET_USER}" >/dev/null 2>&1; then
    usermod -u "${TARGET_UID}" -g "${TARGET_GID}" "${TARGET_USER}" 2>/dev/null || true
else
    useradd -m -u "${TARGET_UID}" -g "${TARGET_GID}" -s /bin/bash "${TARGET_USER}" 2>/dev/null || true
fi

mkdir -p "${WORKSPACE_DIR}"
chown -R "${TARGET_UID}:${TARGET_GID}" "/home/${TARGET_USER}" "${WORKSPACE_DIR}" 2>/dev/null || true

export HOME="/home/${TARGET_USER}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su -s /bin/bash "${TARGET_USER}"
fi

exec su -s /bin/bash "${TARGET_USER}" -c "$*"
