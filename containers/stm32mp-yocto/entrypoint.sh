#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
TARGET_UID="${LOCAL_UID:?LOCAL_UID is required}"
TARGET_GID="${LOCAL_GID:?LOCAL_GID is required}"
TARGET_USER="${LOCAL_USER:?LOCAL_USER is required}"
TARGET_GROUP="${LOCAL_GROUP:?LOCAL_GROUP is required}"
TARGET_HOME="/home/${TARGET_USER}"

existing_group_by_name="$(getent group "${TARGET_GROUP}" | cut -d: -f1 || true)"
existing_group_by_gid="$(getent group "${TARGET_GID}" | cut -d: -f1 || true)"

if [ -n "${existing_group_by_name}" ]; then
    current_group_gid="$(getent group "${TARGET_GROUP}" | cut -d: -f3)"
    if [ "${current_group_gid}" != "${TARGET_GID}" ]; then
        groupmod -g "${TARGET_GID}" "${TARGET_GROUP}"
    fi
    RUNTIME_GROUP="${TARGET_GROUP}"
elif [ -n "${existing_group_by_gid}" ]; then
    if [ "${existing_group_by_gid}" != "${TARGET_GROUP}" ]; then
        groupmod -n "${TARGET_GROUP}" "${existing_group_by_gid}"
    fi
    RUNTIME_GROUP="${TARGET_GROUP}"
else
    groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
    RUNTIME_GROUP="${TARGET_GROUP}"
fi

existing_user_by_name="$(getent passwd "${TARGET_USER}" | cut -d: -f1 || true)"
existing_user_by_uid="$(getent passwd "${TARGET_UID}" | cut -d: -f1 || true)"

if [ -n "${existing_user_by_name}" ]; then
    current_user_uid="$(getent passwd "${TARGET_USER}" | cut -d: -f3)"
    current_user_gid="$(getent passwd "${TARGET_USER}" | cut -d: -f4)"
    current_user_home="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
    if [ "${current_user_uid}" != "${TARGET_UID}" ]; then
        usermod -u "${TARGET_UID}" "${TARGET_USER}"
    fi
    if [ "${current_user_gid}" != "${TARGET_GID}" ]; then
        usermod -g "${RUNTIME_GROUP}" "${TARGET_USER}"
    fi
    if [ "${current_user_home}" != "${TARGET_HOME}" ]; then
        if [ -e "${TARGET_HOME}" ]; then
            usermod -d "${TARGET_HOME}" "${TARGET_USER}"
        else
            usermod -d "${TARGET_HOME}" -m "${TARGET_USER}"
        fi
    fi
    RUNTIME_USER="${TARGET_USER}"
elif [ -n "${existing_user_by_uid}" ]; then
    existing_uid_gid="$(getent passwd "${existing_user_by_uid}" | cut -d: -f4)"
    existing_uid_home="$(getent passwd "${existing_user_by_uid}" | cut -d: -f6)"
    if [ "${existing_user_by_uid}" != "${TARGET_USER}" ]; then
        usermod -l "${TARGET_USER}" "${existing_user_by_uid}"
    fi
    if [ "${existing_uid_gid}" != "${TARGET_GID}" ]; then
        usermod -g "${RUNTIME_GROUP}" "${TARGET_USER}"
    fi
    if [ "${existing_uid_home}" != "${TARGET_HOME}" ]; then
        if [ -e "${TARGET_HOME}" ]; then
            usermod -d "${TARGET_HOME}" "${TARGET_USER}"
        else
            usermod -d "${TARGET_HOME}" -m "${TARGET_USER}"
        fi
    fi
    RUNTIME_USER="${TARGET_USER}"
else
    useradd -m -u "${TARGET_UID}" -g "${RUNTIME_GROUP}" -s /bin/bash "${TARGET_USER}"
    RUNTIME_USER="${TARGET_USER}"
fi

RUNTIME_HOME="$(getent passwd "${RUNTIME_USER}" | cut -d: -f6)"
mkdir -p "${WORKSPACE_DIR}" "${RUNTIME_HOME}"
chown "${TARGET_UID}:${TARGET_GID}" "${RUNTIME_HOME}"

if [ -d "${WORKSPACE_DIR}/.git" ]; then
    su - "${RUNTIME_USER}" -c "git config --global --add safe.directory '${WORKSPACE_DIR}'" >/dev/null 2>&1 || true
fi
if [ -d "${WORKSPACE_DIR}/sources/.repo/repo/.git" ]; then
    su - "${RUNTIME_USER}" -c "git config --global --add safe.directory '${WORKSPACE_DIR}/sources/.repo/repo'" >/dev/null 2>&1 || true
fi
if [ -d "${WORKSPACE_DIR}/sources/.repo/manifests/.git" ]; then
    su - "${RUNTIME_USER}" -c "git config --global --add safe.directory '${WORKSPACE_DIR}/sources/.repo/manifests'" >/dev/null 2>&1 || true
fi

cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
    exec su - "${RUNTIME_USER}"
fi

exec su - "${RUNTIME_USER}" -c "cd '${WORKSPACE_DIR}' && $*"
