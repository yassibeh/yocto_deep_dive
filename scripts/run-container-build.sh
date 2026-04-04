#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

IMAGE_NAME="${IMAGE_NAME:-stm32mp-yocto-toolbox}"
IMAGE_TAG="${IMAGE_TAG:-local}"
CONTAINER_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
WORKSPACE_DIR="/workspace"
CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-ubuntu2404}"

COMMAND="${*:-./scripts/build.sh}"

require_cmd docker

mkdir -p "${DL_DIR}" "${SSTATE_DIR}" "${OUT_DIR}"

log "Running containerized build with image ${CONTAINER_IMAGE}"

docker run --rm -t \
    --hostname "${CONTAINER_HOSTNAME}" \
    -e LOCAL_UID="$(id -u)" \
    -e LOCAL_GID="$(id -g)" \
    -e LOCAL_USER="$(id -un)" \
    -e LOCAL_GROUP="$(id -gn)" \
    -e WORKSPACE_DIR="${WORKSPACE_DIR}" \
    -e SHARED_CACHE_ROOT="${SHARED_CACHE_ROOT}" \
    -e DL_DIR="${DL_DIR}" \
    -e SSTATE_DIR="${SSTATE_DIR}" \
    -e FORCE_DL_CACHEPREFIX="${FORCE_DL_CACHEPREFIX}" \
    -e FORCE_SSTATE_CACHEPREFIX="${FORCE_SSTATE_CACHEPREFIX}" \
    -e ST_AUTO_ACCEPT_EULA="${ST_AUTO_ACCEPT_EULA}" \
    -e MACHINE="${MACHINE}" \
    -e DISTRO="${DISTRO}" \
    -e YOCTO_IMAGE="${YOCTO_IMAGE}" \
    -e BB_NUMBER_THREADS="${BB_NUMBER_THREADS}" \
    -e PARALLEL_MAKE="${PARALLEL_MAKE}" \
    -v "${PROJECT_ROOT}:${WORKSPACE_DIR}" \
    -v "${DL_DIR}:${DL_DIR}" \
    -v "${SSTATE_DIR}:${SSTATE_DIR}" \
    -v "${OUT_DIR}:${OUT_DIR}" \
    "${CONTAINER_IMAGE}" \
    "cd ${WORKSPACE_DIR} && ${COMMAND}"
