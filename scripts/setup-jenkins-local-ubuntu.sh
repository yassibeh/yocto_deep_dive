#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./scripts/setup-jenkins-local-ubuntu.sh \
      --shared-cache-root /absolute/path/to/shared-cache \
      [--jenkins-job yocto-stm32mp13-autobuild] \
      [--jenkins-url http://127.0.0.1:8080]

Purpose:
- install Jenkins on Ubuntu
- ensure the jenkins service is enabled and started
- prepare a shared Yocto cache directory for Jenkins reuse
- grant the current user and Jenkins group access to the shared cache
- print the exact remaining UI steps required to create the Jenkins Pipeline job

Notes:
- this script is intended for a local Ubuntu host
- it uses sudo/systemctl/apt and therefore changes the machine state
- the Jenkins job itself is still created from SCM using jenkins/Jenkinsfile
- machine-specific paths stay outside tracked repo config and are provided as arguments/env vars
EOF
}

JENKINS_JOB="yocto-stm32mp13-autobuild"
JENKINS_URL="http://127.0.0.1:8080"
SHARED_CACHE_ROOT=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --shared-cache-root)
            SHARED_CACHE_ROOT="$2"
            shift 2
            ;;
        --jenkins-job)
            JENKINS_JOB="$2"
            shift 2
            ;;
        --jenkins-url)
            JENKINS_URL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "${SHARED_CACHE_ROOT}" ]; then
    echo "ERROR: --shared-cache-root is required" >&2
    usage >&2
    exit 1
fi

if [ "${SHARED_CACHE_ROOT#/}" = "${SHARED_CACHE_ROOT}" ]; then
    echo "ERROR: --shared-cache-root must be an absolute path" >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

CURRENT_USER="$(id -un)"
CACHE_DOWNLOADS="${SHARED_CACHE_ROOT}/downloads"
CACHE_SSTATE="${SHARED_CACHE_ROOT}/sstate-cache"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

require_cmd apt-get
require_cmd systemctl
require_cmd getent
require_cmd install
require_cmd chmod
require_cmd chown
require_cmd find
require_cmd id

log "Installing Jenkins and required host packages"
${SUDO} apt-get update
${SUDO} apt-get install -y \
    openjdk-17-jre-headless \
    jenkins \
    git \
    repo \
    python3 \
    python3-pip \
    python3-pexpect \
    python3-git \
    python3-jinja2 \
    gawk \
    wget \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    build-essential \
    chrpath \
    socat \
    cpio \
    xz-utils \
    debianutils \
    iputils-ping \
    libsdl1.2-dev \
    pylint \
    xterm \
    bsdmainutils \
    libssl-dev \
    libgmp-dev \
    libmpc-dev \
    lz4 \
    zstd \
    git-lfs \
    libusb-1.0-0 \
    file \
    rsync

log "Enabling and starting Jenkins service"
${SUDO} systemctl enable --now jenkins

log "Preparing shared Yocto cache at ${SHARED_CACHE_ROOT}"
${SUDO} install -d -m 2775 -o "${CURRENT_USER}" -g jenkins "${SHARED_CACHE_ROOT}"
${SUDO} install -d -m 2775 -o "${CURRENT_USER}" -g jenkins "${CACHE_DOWNLOADS}"
${SUDO} install -d -m 2775 -o "${CURRENT_USER}" -g jenkins "${CACHE_SSTATE}"

${SUDO} chown -R "${CURRENT_USER}:jenkins" "${SHARED_CACHE_ROOT}"
${SUDO} find "${SHARED_CACHE_ROOT}" -type d -exec chmod 2775 {} \;
${SUDO} find "${SHARED_CACHE_ROOT}" -type f -exec chmod 0664 {} \; || true

log "Adding ${CURRENT_USER} to jenkins group"
${SUDO} usermod -aG jenkins "${CURRENT_USER}"

log "Configuring Git trust for Jenkins shared cache reuse"
${SUDO} -u jenkins git config --global --replace-all safe.directory '*'

cat <<EOF

Local Jenkins bootstrap completed.

What was configured:
- Jenkins service installed and started
- shared cache root prepared: ${SHARED_CACHE_ROOT}
- downloads cache: ${CACHE_DOWNLOADS}
- sstate cache: ${CACHE_SSTATE}
- jenkins Git safe.directory set to '*'

Open Jenkins:
- ${JENKINS_URL}

Recommended Jenkins node label:
- yocto-linux

Create a Pipeline job with:
- Job name: ${JENKINS_JOB}
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: <your repository clone URL>
- Branch: your working branch, for example */feature/yocto-autobuild-stm32mp135f-dk
- Script Path: jenkins/Jenkinsfile

Then set Jenkins environment variables either at the job level or globally:
- SHARED_CACHE_ROOT=${SHARED_CACHE_ROOT}
- DL_DIR=${CACHE_DOWNLOADS}
- SSTATE_DIR=${CACHE_SSTATE}
- FORCE_DL_CACHEPREFIX=${SHARED_CACHE_ROOT}
- FORCE_SSTATE_CACHEPREFIX=${SHARED_CACHE_ROOT}

Important:
- log out and back in if you want the new jenkins group membership to apply to your interactive shell
- this script does not create the Jenkins job via API; it prepares the host and prints the exact UI configuration
EOF
