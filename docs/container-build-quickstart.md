# Container Build Quick Start

This document describes the local containerized build flow for the STM32MP135F-DK OpenSTLinux target.

## Scope

Validated target for this branch:
- `MACHINE=stm32mp13-disco`
- `DISTRO=openstlinux-weston`
- `YOCTO_IMAGE=core-image-minimal`

## 1. Install container host dependencies

```bash
./scripts/install-host-deps-container-ubuntu.sh
```

If Docker access is granted by adding your user to the `docker` group, refresh the current shell before continuing.

Recommended command:

```bash
exec sg docker newgrp
```

Then verify:

```bash
id
docker version
```

Continue only when:
- `id` shows the `docker` group
- `docker version` shows both Client and Server

## 2. Build the local container image

```bash
./scripts/build-container-image.sh
```

Default image tag:

```text
stm32mp-yocto-toolbox:local
```

## 3. Run the containerized build

```bash
./scripts/run-container-build.sh
```

This mounts the repository workspace and the configured Yocto cache directories into the container and runs the repository build wrapper inside the container.
The container runtime mirrors the invoking host username and uses a configurable container hostname.

## 4. Override cache paths if needed

Example:

```bash
export SHARED_CACHE_ROOT=/srv/yocto-cache/shared
export DL_DIR=/srv/yocto-cache/shared/downloads
export SSTATE_DIR=/srv/yocto-cache/shared/sstate-cache
export FORCE_DL_CACHEPREFIX=/srv/yocto-cache/shared
export FORCE_SSTATE_CACHEPREFIX=/srv/yocto-cache/shared
./scripts/run-container-build.sh
```

## 5. Run a different command inside the same container environment

Examples:

```bash
./scripts/run-container-build.sh ./scripts/bootstrap-manifest.sh
./scripts/run-container-build.sh ./scripts/archive-artifacts.sh
```

Manual interactive shell example:

```bash
docker run --rm -it \
  --hostname "${CONTAINER_HOSTNAME:-ubuntu2404}" \
  -e LOCAL_UID="$(id -u)" \
  -e LOCAL_GID="$(id -g)" \
  -e LOCAL_USER="$(id -un)" \
  -e LOCAL_GROUP="$(id -gn)" \
  -e WORKSPACE_DIR=/workspace \
  -v "$(pwd)":/workspace \
  stm32mp-yocto-toolbox:local
```

## Notes

- ST upstream `envsetup.sh` remains unchanged and is still sourced by the repository wrapper.
- Machine-specific paths stay outside tracked files and are provided through environment variables.
- The container is intended to be disposable; caches and artifacts remain on the host through bind mounts.
