#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

IMAGE_NAME="${IMAGE_NAME:-stm32mp-yocto-toolbox}"
IMAGE_TAG="${IMAGE_TAG:-local}"
CONTAINER_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
CONTAINER_PROFILE="${CONTAINER_PROFILE:-ubuntu2404}"
WORKSPACE_DIR="/workspace"

case "${CONTAINER_PROFILE}" in
    ubuntu2004)
        DEFAULT_CONTAINER_HOSTNAME="ubuntu20"
        ;;
    ubuntu2204)
        DEFAULT_CONTAINER_HOSTNAME="ubuntu22"
        ;;
    ubuntu2404)
        DEFAULT_CONTAINER_HOSTNAME="ubuntu24"
        ;;
    *)
        DEFAULT_CONTAINER_HOSTNAME="${CONTAINER_PROFILE}"
        ;;
esac

CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-${DEFAULT_CONTAINER_HOSTNAME}}"

require_cmd docker

exec docker run --rm -it \
    --hostname "${CONTAINER_HOSTNAME}" \
    -e LOCAL_UID="$(id -u)" \
    -e LOCAL_GID="$(id -g)" \
    -e LOCAL_USER="$(id -un)" \
    -e LOCAL_GROUP="$(id -gn)" \
    -e WORKSPACE_DIR="${WORKSPACE_DIR}" \
    -v "${PROJECT_ROOT}:${WORKSPACE_DIR}" \
    "${CONTAINER_IMAGE}"
