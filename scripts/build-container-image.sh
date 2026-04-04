#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-stm32mp-yocto-toolbox}"
IMAGE_TAG="${IMAGE_TAG:-local}"

cd "${PROJECT_ROOT}"

docker build \
    -f containers/stm32mp-yocto/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo "Built ${IMAGE_NAME}:${IMAGE_TAG}"
