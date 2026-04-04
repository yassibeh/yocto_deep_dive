#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

PACKAGES=(
    docker.io
)

${SUDO} apt-get update
${SUDO} apt-get install -y "${PACKAGES[@]}"

cat <<'EOF'
Container host dependency installation completed.

Recommended next steps:
1. ./scripts/build-container-image.sh
2. ./scripts/run-container-build.sh
EOF
