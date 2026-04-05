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

BUILD_ARGS=(
    --build-arg BASE_IMAGE="${BASE_IMAGE}"
)

STAGED_VENDOR_DIR="containers/stm32mp-yocto/vendor/staged"
rm -rf "${STAGED_VENDOR_DIR}"
mkdir -p "${STAGED_VENDOR_DIR}"
cleanup() {
    rm -rf "${STAGED_VENDOR_DIR}"
}
trap cleanup EXIT

if [ -n "${STM32CUBEPROG_BUNDLE:-}" ]; then
    staged_bundle="${STAGED_VENDOR_DIR}/$(basename "${STM32CUBEPROG_BUNDLE}")"
    cp -f "${STM32CUBEPROG_BUNDLE}" "${staged_bundle}"
    BUILD_ARGS+=(--build-arg STM32CUBEPROG_BUNDLE="${staged_bundle}")
fi

if [ -n "${STM32CUBEPROG_DIR:-}" ]; then
    staged_dir="${STAGED_VENDOR_DIR}/$(basename "${STM32CUBEPROG_DIR}")"
    rm -rf "${staged_dir}"
    cp -a "${STM32CUBEPROG_DIR}" "${staged_dir}"
    BUILD_ARGS+=(--build-arg STM32CUBEPROG_DIR="${staged_dir}")
fi

docker build \
    "${BUILD_ARGS[@]}" \
    -f containers/stm32mp-yocto/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo "Built ${IMAGE_NAME}:${IMAGE_TAG} from ${BASE_IMAGE} (${CONTAINER_PROFILE})"
