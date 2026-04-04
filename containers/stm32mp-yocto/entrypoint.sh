#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
TARGET_UID="${LOCAL_UID:?LOCAL_UID is required}"
TARGET_GID="${LOCAL_GID:?LOCAL_GID is required}"
TARGET_USER="${LOCAL_USER:?LOCAL_USER is required}"
TARGET_GROUP="${LOCAL_GROUP:?LOCAL_GROUP is required}"

existing_group_by_name="$(getent group "${TARGET_GROUP}" | cut -d: -f1 || true)"
existing_group_by_gid="$(getent group "${TARGET_GID}" | cut -d: -f1 || true)"
if [ -n "${existing_group_by_name}" ]; then
    RUNTIME_GROUP="${TARGET_GROUP}"
elif [ -n "${existing_group_by_gid}" ]; then
    RUNTIME_GROUP="${existing_group_by_gid}"
else
    groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
    RUNTIME_GROUP="${TARGET_GROUP}"
fi

existing_user_by_name="$(getent passwd "${TARGET_USER}" | cut -d: -f1 || true)"
existing_user_by_uid="$(getent passwd "${TARGET_UID}" | cut -d: -f1 || true)"
if [ -n "${existing_user_by_name}" ]; then
    RUNTIME_USER="${TARGET_USER}"
elif [ -n "${existing_user_by_uid}" ]; then
    RUNTIME_USER="${existing_user_by_uid}"
else
    useradd -m -u "${TARGET_UID}" -g "${RUNTIME_GROUP}" -s /bin/bash "${TARGET_USER}"
    RUNTIME_USER="${TARGET_USER}"
fi

RUNTIME_HOME="$(getent passwd "${RUNTIME_USER}" | cut -d: -f6)"
mkdir -p "${WORKSPACE_DIR}" "${RUNTIME_HOME}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su "${RUNTIME_USER}"
fi

exec su "${RUNTIME_USER}" -c "cd '${WORKSPACE_DIR}' && $*"
