# Architecture

## Scope

This repository automates a first Yocto build for:
- board: STM32MP135F-DK (`MACHINE=stm32mp13-disco`)
- image: `core-image-minimal`
- base distribution: ST OpenSTLinux from the official `oe-manifest`
- execution models:
  - host-based local/Jenkins build
  - containerized local build on the dedicated container branch

## Phase plan

### Phase 1: unsigned autobuild

Objective:
- prove that checkout, environment setup, bitbake build, and artifact collection are stable

Properties:
- uses official ST manifest
- non-interactive ST EULA acceptance is supported for CI
- no private signing keys in CI
- runs directly on a controlled host
- archives outputs for inspection

### Phase 2: reproducibility and maintenance

Add:
- host dependency documentation
- persistent download and sstate caches
- containerized build environment for portability
- build retention policy
- branch/tag policies
- optional nightly job

### Phase 3: release and signing

Add:
- separate release job
- manual approval gate
- restricted signing node or HSM-backed signing
- immutable release artifact publication

## Directory intent

- `sources/` : repo-managed ST Yocto sources
- `build/` : active OpenEmbedded build directory
- `${PROJECT_ROOT}/.yocto-cache/downloads/` or overridden `DL_DIR` : Yocto source downloads cache
- `${PROJECT_ROOT}/.yocto-cache/sstate-cache/` or overridden `SSTATE_DIR` : Yocto shared-state cache
- `out/` : copied outputs intended for CI archival

## Security model

Phase 1 explicitly excludes private secure-boot material from the autobuild path.

Rationale:
- avoid leaking keys into generic build logs, workspaces, or agents
- keep unsigned build validation independent from release-signing design
- introduce key handling only after build automation is proven stable
