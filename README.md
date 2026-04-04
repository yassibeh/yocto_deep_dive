# yocto_deep_dive

Automated Yocto build setup for the STM32MP13 Discovery Kit using the official ST OpenSTLinux manifest.

Current target:
- Board: STM32MP135F-DK
- ST machine name: `stm32mp13-disco`
- Distro: `openstlinux-weston`
- Image: `core-image-minimal`
- Host: Ubuntu, no Docker
- CI: Jenkins pipeline from SCM
- ST EULA: auto-accepted by default for non-interactive CI builds

## Purpose

This repository provides a clean starting point to:
- fetch the official ST Yocto sources
- configure the OpenSTLinux build environment
- build a test image
- archive build outputs
- prepare a Jenkins-based continuous integration flow

## Repository structure

- `config/build.env` : build parameters
- `scripts/install-host-deps-ubuntu.sh` : install required Ubuntu host packages
- `scripts/bootstrap-manifest.sh` : initialize and sync ST sources
- `scripts/build.sh` : configure environment and run BitBake
- `scripts/archive-artifacts.sh` : copy useful outputs to `out/`
- `scripts/check-host-deps.sh` : quick host tooling check
- `jenkins/Jenkinsfile` : Jenkins pipeline definition
- `docs/` : design and implementation notes

## Shared Yocto cache

By default the project uses a repo-local cache layout:
- downloads: `${PROJECT_ROOT}/.yocto-cache/downloads`
- sstate: `${PROJECT_ROOT}/.yocto-cache/sstate-cache`

You can override these paths with environment variables before running the scripts:

```bash
export SHARED_CACHE_ROOT=/path/to/shared-cache
export DL_DIR=/path/to/shared-cache/downloads
export SSTATE_DIR=/path/to/shared-cache/sstate-cache
```

This allows the same repository to work on any machine without editing tracked files.

## Current validation status

Validated on the current Ubuntu host:
- required host tools present
- official ST manifest bootstrap successful
- OpenSTLinux environment initialization successful

Known integration notes:
- ST `envsetup.sh` is sourced by the wrapper with `nounset` temporarily disabled because the upstream script references some unset variables during initialization
- the wrapper does not export `BUILD_DIR` before sourcing the ST script because upstream treats that variable as an explicit override and rejects the positional build-directory argument in that case
- upstream cleanup at the end of `envsetup.sh` unsets variables such as `MACHINE` and `DISTRO`, so the wrapper preserves its own target values before sourcing the ST script
- the generated ST default `bblayers.conf` template does not enable all required `meta-openembedded` dependency layers for this setup, so the wrapper patches in `meta-oe` and `meta-python` automatically
- the valid machine identifier in the ST manifest is `stm32mp13-disco`; `stm32mp135f-dk` is the board name, not the Yocto `MACHINE` value used by this release
- if an existing build directory contains a mismatched previous `DISTRO` or `MACHINE`, the wrapper archives it automatically and recreates a clean ST build directory for the requested target
- for CI use, the wrapper can export `ACCEPT_EULA_<MACHINE>=1` automatically so the ST setup does not stop on an interactive EULA prompt

## Quick start

### 1. Go to the project directory

```bash
cd /path/to/yocto_deep_dive
```

### 2. Install Ubuntu host dependencies

```bash
./scripts/install-host-deps-ubuntu.sh
```

This script installs the host packages required by the ST OpenSTLinux environment on Ubuntu.

### 3. Check host tools

```bash
./scripts/check-host-deps.sh
```

### 4. Fetch and sync the ST manifest

```bash
./scripts/bootstrap-manifest.sh
```

### 5. Run the build

```bash
./scripts/build.sh
```

### 6. Archive build outputs

```bash
./scripts/archive-artifacts.sh
```

## Main configuration file

Edit `config/build.env` if needed.

Important variables:
- `ST_MANIFEST_TAG`
- `MACHINE`
- `DISTRO`
- `YOCTO_IMAGE`
- `DL_DIR`
- `SSTATE_DIR`
- `ST_AUTO_ACCEPT_EULA`

## Build output

The ST build directory is created under:

```bash
sources/build-openstlinux-weston-stm32mp13-disco
```

Archived outputs are copied to:

```bash
out/
```

## Jenkins usage

Use a Jenkins Pipeline job configured as:
- Pipeline from SCM
- repository: this repository
- script path: `jenkins/Jenkinsfile`

Current pipeline stages:
- Checkout
- Host validation
- Source bootstrap
- Environment validation
- Build
- Archive outputs

## ST EULA handling

For non-interactive CI runs, the wrapper exports the ST-supported variable:

```bash
ACCEPT_EULA_stm32mp13-disco=1
```

This is enabled by default through:

```bash
ST_AUTO_ACCEPT_EULA=1
```

To disable automatic acceptance and use the upstream interactive flow instead:

```bash
export ST_AUTO_ACCEPT_EULA=0
```

## Security note

This first implementation does not include secure-boot private keys in CI.

Recommended approach:
- validate unsigned builds first
- add signing later in a separate restricted release pipeline

## Additional documentation

- `docs/architecture.md`
- `docs/jenkins-company-setup.md`
- `docs/secure-boot-signing-strategy.md`
