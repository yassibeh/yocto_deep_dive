#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

TIMESTAMP="${1:-$(date +%Y%m%d-%H%M%S)}"
DEST_DIR="${OUT_DIR}/${TIMESTAMP}"
META_DIR="${DEST_DIR}/metadata"
mkdir -p "${META_DIR}"

{
    echo "timestamp=${TIMESTAMP}"
    echo "project_root=${PROJECT_ROOT}"
    echo "machine=${MACHINE}"
    echo "distro=${DISTRO}"
    echo "yocto_image=${YOCTO_IMAGE}"
    echo "container_profile=${CONTAINER_PROFILE:-unset}"
    echo "container_image=${IMAGE_NAME:-stm32mp-yocto-toolbox}:${IMAGE_TAG:-local}"
    echo "build_dir=${ST_BUILD_DIR}"
    echo "deploy_dir=${ST_DEPLOY_DIR}/images/${MACHINE}"
} > "${META_DIR}/build.env.resolved"

git rev-parse HEAD > "${META_DIR}/git-commit.txt"
git status --short > "${META_DIR}/git-status.txt" || true
git log -1 --decorate --stat > "${META_DIR}/git-commit-summary.txt"

if [ -d "${MANIFEST_DIR}/.repo/manifests" ]; then
    git -C "${MANIFEST_DIR}/.repo/manifests" rev-parse HEAD > "${META_DIR}/manifest-git-head.txt"
    git -C "${MANIFEST_DIR}/.repo/manifests" log -1 --decorate --stat > "${META_DIR}/manifest-git-summary.txt"
fi

if command -v repo >/dev/null 2>&1 && [ -d "${MANIFEST_DIR}/.repo" ]; then
    (
        cd "${MANIFEST_DIR}"
        repo manifest -r -o "${META_DIR}/repo-manifest-pinned.xml"
    )
fi

if command -v docker >/dev/null 2>&1; then
    docker version > "${META_DIR}/docker-version.txt"
    docker image inspect "${IMAGE_NAME:-stm32mp-yocto-toolbox}:${IMAGE_TAG:-local}" > "${META_DIR}/container-image-inspect.json"
fi

if [ -d "${ST_DEPLOY_DIR}/images/${MACHINE}" ]; then
    find "${ST_DEPLOY_DIR}/images/${MACHINE}" -maxdepth 1 -type f \( -name '*.manifest' -o -name '*.testdata.json' -o -name '*.json' -o -name '*.env' -o -name 'core-image-*' -o -name '*Image*' -o -name '*u-boot*' -o -name '*tf-a*' -o -name '*.tsv' -o -name '*.ext4' -o -name '*.tar.xz' -o -name '*.wic' -o -name '*.sdcard' -o -name '*.stm32' -o -name '*.sha256' -o -name '*.bmap' \) | sort > "${META_DIR}/deploy-file-list.txt"
fi

log "Build metadata collected in ${META_DIR}"
