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

Choose the container profile explicitly before building.

Example:

```bash
export CONTAINER_PROFILE=ubuntu2404
./scripts/build-container-image.sh
```

Supported values currently are:
- `ubuntu2004`
- `ubuntu2204`
- `ubuntu2404`

Default image tag:

```text
stm32mp-yocto-toolbox:local
```

## 3. Run the containerized build

```bash
export CONTAINER_PROFILE=ubuntu2404
./scripts/run-container-build.sh
```

This mounts the repository workspace and the configured Yocto cache directories into the container and runs the repository build wrapper inside the container.
The container runtime mirrors the invoking host username and uses a configurable container hostname.
The hostname is derived from `CONTAINER_PROFILE` unless you override it explicitly with `CONTAINER_HOSTNAME`.

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
  --hostname "${CONTAINER_HOSTNAME:-${CONTAINER_PROFILE:?set CONTAINER_PROFILE}}" \
  -e LOCAL_UID="$(id -u)" \
  -e LOCAL_GID="$(id -g)" \
  -e LOCAL_USER="$(id -un)" \
  -e LOCAL_GROUP="$(id -gn)" \
  -e WORKSPACE_DIR=/workspace \
  -v "$(pwd)":/workspace \
  stm32mp-yocto-toolbox:local
```

Explicit hostname override still wins:

```bash
export CONTAINER_PROFILE=ubuntu2404
export CONTAINER_HOSTNAME=st-yocto-dev
./scripts/run-container-build.sh
```

## 6. Optional STM32CubeProgrammer integration

This repository does not bundle STM32CubeProgrammer inside the default build container.
That is intentional.

Reasoning:
- it matches the upstream pattern seen in ST/OpenSTLinux-adjacent projects
- it avoids forcing vendor installer/license handling into the default build image
- it keeps the default container focused on reproducible artifact generation

Supported workflow:
- build OpenSTLinux artifacts in the container
- use a host-installed or separately mounted `STM32_Programmer_CLI` afterwards

Helper examples:

```bash
./scripts/stm32cubeprogrammer.sh --help
./scripts/stm32cubeprogrammer.sh list-usb
./scripts/stm32cubeprogrammer.sh flash-layout USB1 /absolute/path/to/FlashLayout_emmc_stm32mp13-disco_trusted.tsv
```

If auto-detection does not find the CLI, point to it explicitly:

```bash
export STM32CUBEPROGRAMMER_CLI=/usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI
```

## Notes

- ST upstream `envsetup.sh` remains unchanged and is still sourced by the repository wrapper.
- Machine-specific paths stay outside tracked files and are provided through environment variables.
- The container is intended to be disposable; caches and artifacts remain on the host through bind mounts.
- The validated OpenSTLinux deploy path for this branch is under `tmp-glibc/deploy`, not `tmp/deploy`.
