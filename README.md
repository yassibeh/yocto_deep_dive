# Yocto autobuild for STM32MP135F-DK

Professional starter setup for automating an OpenSTLinux Yocto build on a local Ubuntu host, without Docker, using Jenkins.

Initial scope:
- board: `stm32mp135f-dk`
- base: official ST `oe-manifest`
- image: `core-image-minimal`
- host execution: directly on the PC
- signing/secure-boot keys: intentionally excluded from the first CI implementation

## Goal

Get a reproducible first autobuild working before introducing release signing.

The first milestone is:
1. checkout the official STM32 Yocto manifest
2. initialize the OpenSTLinux build environment
3. build `core-image-minimal` for `stm32mp135f-dk`
4. archive logs and deploy artifacts
5. structure the repository so Jenkins can run it cleanly

## Repository layout

- `config/build.env` : build parameters used by scripts and Jenkins
- `scripts/bootstrap-manifest.sh` : initializes or syncs the ST manifest workspace
- `scripts/build.sh` : launches the Yocto build
- `scripts/archive-artifacts.sh` : copies deploy artifacts and logs into `out/`
- `jenkins/Jenkinsfile` : starter Jenkins pipeline
- `docs/` : implementation notes and next steps

## First-use flow

### 1. Review build parameters

Edit:

`config/build.env`

Main values:
- `ST_MANIFEST_TAG`
- `MACHINE`
- `DISTRO`
- `YOCTO_IMAGE`
- shared cache paths

### 2. Bootstrap the manifest workspace

```bash
cd /path/to/yocto_deep_dive
./scripts/bootstrap-manifest.sh
```

### 3. Start a manual test build

```bash
cd /path/to/yocto_deep_dive
./scripts/build.sh
```

### 4. Inspect archived outputs

```bash
ls -R out/
```

## Jenkins

The starter pipeline lives in:

`jenkins/Jenkinsfile`

It is designed for a Jenkins job that points to this repository and runs directly on a Linux machine with Yocto host dependencies installed.

## Shared cache usage

This setup is now configured to reuse the existing host caches:

- downloads: `${PROJECT_ROOT}/.yocto-cache/downloads`
- sstate: `${PROJECT_ROOT}/.yocto-cache/sstate-cache`

That is the right approach for Jenkins on the same machine because it:
- reduces fetch time
- avoids rebuilding already-covered tasks
- keeps cache management centralized across Yocto workspaces

## Security position for phase 1

Private secure-boot keys are not integrated into this first autobuild.

Reason:
- first get deterministic unsigned builds working
- keep private keys off the general build path
- add signing later as a separate restricted release stage

See:
- `docs/architecture.md`
- `docs/secure-boot-signing-strategy.md`

## Current implementation status

Implemented in this repo:
- starter repo structure
- bootstrap/build/archive scripts
- Jenkins starter pipeline
- phase-based architecture notes

Not implemented yet:
- Jenkins installation on host
- signing pipeline
- release approval flow
- artifact repository publication
- metrics/notifications
