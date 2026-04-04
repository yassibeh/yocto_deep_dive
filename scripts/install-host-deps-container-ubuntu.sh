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
1. If Docker group membership was just granted, refresh this shell:
   exec sg docker newgrp
2. Verify Docker access:
   id
   docker version
3. Build the validated default profile image:
   export CONTAINER_PROFILE=ubuntu2404
   ./scripts/build-container-image.sh
4. Run the containerized ST build:
   export CONTAINER_PROFILE=ubuntu2404
   ./scripts/run-container-build.sh
EOF
