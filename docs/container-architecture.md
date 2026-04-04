# Container Architecture for ST OpenSTLinux Build

## Goal

Provide a portable containerized build environment for the STM32MP135F-DK OpenSTLinux Yocto build using the official ST `oe-manifest`, while keeping the repository portable and upstream-friendly.

Target build in this branch:
- Board: STM32MP135F-DK
- Yocto `MACHINE`: `stm32mp13-disco`
- `DISTRO`: `openstlinux-weston`
- image: `core-image-minimal`

## Scope of this branch

This branch focuses only on:
- building the ST OpenSTLinux target successfully inside a container
- keeping ST upstream scripts untouched
- reusing existing wrapper logic from this repository where possible
- structuring the container environment so it is portable across machines
- documenting how a new user can run the containerized build from a fresh clone

Out of scope for this branch:
- Jenkins integration
- Jenkins-in-container
- release signing flow
- private key handling

## High-level model

Recommended execution split:
- host: Git checkout, Docker engine, persistent cache directories
- container: Yocto build dependencies, ST/OpenSTLinux tooling prerequisites, optional STM32 tooling support
- repo scripts: project-specific orchestration and ST integration logic

This means:
- Docker provides the build environment
- ST `oe-manifest` remains the source of truth for the Yocto workspace
- `layers/meta-st/scripts/envsetup.sh` is still sourced during the build
- local wrapper scripts remain responsible for cache setup, EULA handling, and config normalization

## Design principles

1. Do not modify ST upstream scripts.
2. Keep machine-specific paths outside tracked configuration.
3. Keep private signing keys outside the image and outside the repository.
4. Use bind-mounted persistent directories for source downloads, sstate cache, and artifacts.
5. Mirror the invoking host username at container runtime while keeping the container hostname configurable and derived from the selected container profile/distro.
6. Reuse proven container patterns instead of inventing a completely custom Yocto flow.

## Existing external references

Useful references that inform this design:
- ST/OpenSTLinux Docker examples:
  - `kbumsik/docker-build-yocto`
  - `rsippl/yocto-env-st`
- Generic Yocto container references:
  - `bisdn/docker-yocto-builder`
  - `crops/yocto-dockerfiles`

These references are design inputs only. This repository remains responsible for:
- ST `oe-manifest` bootstrap
- wrapper behavior around `envsetup.sh`
- portable project layout
- documentation and reproducible steps

## Target repository additions

Planned additions in this branch:
- `containers/stm32mp-yocto/`
  - Dockerfile
  - entrypoint or helper scripts
- `scripts/`
  - image build helper
  - container run helper for local builds
- README updates for the containerized build flow

## Expected runtime flow

1. Build or pull the project container image.
2. Start the container with mounted host directories for:
   - repository workspace
   - `DL_DIR`
   - `SSTATE_DIR`
   - output artifacts
3. Inside the container:
   - run the existing project wrapper scripts
   - initialize the ST manifest
   - source ST `envsetup.sh`
   - normalize configuration
   - run `bitbake core-image-minimal`
4. Copy or expose artifacts on the mounted host filesystem.

## Portability requirements

The container flow must work without hardcoded usernames or personal paths.

So the implementation should:
- derive project root dynamically
- allow user/group mapping through environment variables or runtime parameters
- allow cache locations to be overridden through environment variables
- allow the container hostname to be configured from the selected container profile/distro
- avoid embedding host-specific absolute paths in tracked files

## Tooling scope

Container image should eventually be able to host:
- Yocto/OpenEmbedded host dependencies
- ST manifest prerequisites
- STM32CubeProgrammer CLI
- STM32 signing tools where installable and legally distributable

However, this branch validates the Yocto build path first. Vendor tooling integration must not block the initial containerized build validation.

## Acceptance criteria for this branch

This branch is considered successful when:
- the ST `oe-manifest` workspace can be bootstrapped inside the container
- the existing wrapper flow can source ST `envsetup.sh` inside the container
- `core-image-minimal` builds successfully for `stm32mp13-disco`
- the flow is documented and portable for a fresh user cloning the repository
- the implementation avoids hardcoded machine-specific data in tracked files
