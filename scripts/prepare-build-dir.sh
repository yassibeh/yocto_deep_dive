#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

LOCAL_CONF="${ST_BUILD_DIR}/conf/local.conf"

if [ ! -f "${LOCAL_CONF}" ]; then
    exit 0
fi

current_distro=$(sed -n 's/^DISTRO[[:space:]]*??=[[:space:]]*"\([^"]*\)".*/\1/p' "${LOCAL_CONF}" | tail -n1)
current_machine=$(sed -n 's/^MACHINE[[:space:]]*??=[[:space:]]*"\([^"]*\)".*/\1/p' "${LOCAL_CONF}" | tail -n1)

if [ "${current_distro:-}" = "${DISTRO}" ] && [ "${current_machine:-}" = "${MACHINE}" ]; then
    exit 0
fi

backup_dir="${ST_BUILD_DIR}.bak-$(date +%Y%m%d-%H%M%S)"
log "Existing build directory does not match requested DISTRO/MACHINE"
log "Archiving ${ST_BUILD_DIR} to ${backup_dir}"
mv "${ST_BUILD_DIR}" "${backup_dir}"
