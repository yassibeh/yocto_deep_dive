#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

PACKAGES=(
    gawk
    wget
    git
    diffstat
    unzip
    texinfo
    gcc-multilib
    build-essential
    chrpath
    socat
    cpio
    python3
    python3-pip
    python3-pexpect
    xz-utils
    debianutils
    iputils-ping
    python3-git
    python3-jinja2
    libsdl1.2-dev
    pylint
    xterm
    bsdmainutils
    libssl-dev
    libgmp-dev
    libmpc-dev
    lz4
    zstd
    git-lfs
    libusb-1.0-0
)

${SUDO} apt-get update
${SUDO} apt-get install -y "${PACKAGES[@]}"

cat <<'EOF'
Host dependency installation completed.

Recommended next steps:
1. ./scripts/check-host-deps.sh
2. ./scripts/bootstrap-manifest.sh
3. ./scripts/build.sh
EOF
