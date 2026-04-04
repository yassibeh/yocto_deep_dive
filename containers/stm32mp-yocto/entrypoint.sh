#!/usr/bin/env bash
set -euo pipefail

TARGET_UID="${LOCAL_UID:-1000}"
TARGET_GID="${LOCAL_GID:-1000}"
TARGET_USER="${LOCAL_USER:-builder}"
TARGET_GROUP="${LOCAL_GROUP:-builder}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
RUNTIME_USER="builder"
RUNTIME_GROUP="builder"

existing_group_by_gid="$(getent group "${TARGET_GID}" | cut -d: -f1 || true)"
if [ -n "${existing_group_by_gid}" ]; then
    RUNTIME_GROUP="${existing_group_by_gid}"
else
    groupmod -g "${TARGET_GID}" "${RUNTIME_GROUP}"
fi

existing_user_by_uid="$(getent passwd "${TARGET_UID}" | cut -d: -f1 || true)"
if [ -n "${existing_user_by_uid}" ]; then
    RUNTIME_USER="${existing_user_by_uid}"
else
    if [ "${RUNTIME_GROUP}" != "builder" ]; then
        usermod -g "${TARGET_GID}" builder
    fi
    usermod -u "${TARGET_UID}" builder
fi

RUNTIME_HOME="$(getent passwd "${RUNTIME_USER}" | cut -d: -f6 || true)"
if [ -z "${RUNTIME_HOME}" ]; then
    RUNTIME_HOME="/home/${RUNTIME_USER}"
fi

mkdir -p "${WORKSPACE_DIR}" "${RUNTIME_HOME}"
chown -R "${TARGET_UID}:${TARGET_GID}" "${RUNTIME_HOME}" "${WORKSPACE_DIR}" 2>/dev/null || true

export HOME="${RUNTIME_HOME}"
export USER="${RUNTIME_USER}"
export LOGNAME="${RUNTIME_USER}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su -s /bin/bash "${RUNTIME_USER}"
fi

exec su -s /bin/bash "${RUNTIME_USER}" -c "$*"
