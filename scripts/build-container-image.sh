#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-stm32mp-yocto-toolbox}"
IMAGE_TAG="${IMAGE_TAG:-local}"
CONTAINER_PROFILE="${CONTAINER_PROFILE:-ubuntu2404}"

case "${CONTAINER_PROFILE}" in
    ubuntu2004)
        BASE_IMAGE="ubuntu:20.04"
        ;;
    ubuntu2204)
        BASE_IMAGE="ubuntu:22.04"
        ;;
    ubuntu2404)
        BASE_IMAGE="ubuntu:24.04"
        ;;
    *)
        echo "Unsupported CONTAINER_PROFILE: ${CONTAINER_PROFILE}" >&2
        exit 1
        ;;
esac

cd "${PROJECT_ROOT}"

docker build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    -f containers/stm32mp-yocto/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo "Built ${IMAGE_NAME}:${IMAGE_TAG} from ${BASE_IMAGE} (${CONTAINER_PROFILE})"
