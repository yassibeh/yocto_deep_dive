# yocto_deep_dive

Automated Yocto build setup for the STM32MP13 Discovery Kit using the official ST OpenSTLinux manifest.

Current target:
- Board: STM32MP135F-DK
- ST machine name: `stm32mp13-disco`
- Distro: `openstlinux-weston`
- Image: `core-image-minimal`
- Host: Ubuntu
- CI: Jenkins pipeline from SCM
- ST EULA: auto-accepted by default for non-interactive CI builds

Branch note:
- `main` / current host-build branch documents the validated host-based and Jenkins-based workflow
- `feature/containerized-st-yocto-build` focuses on validating the same ST `oe-manifest` build flow inside a portable container before any Jenkins/container integration work

## Purpose

This repository provides a clean starting point to:
- fetch the official ST Yocto sources
- configure the OpenSTLinux build environment
- build a test image
- archive build outputs
- prepare a Jenkins-based continuous integration flow

## Repository structure

- `config/build.env` : build parameters
- `scripts/install-host-deps-ubuntu.sh` : install required Ubuntu host packages for local builds
- `scripts/install-host-deps-container-ubuntu.sh` : install host-side container prerequisites for local containerized builds
- `scripts/setup-jenkins-local-ubuntu.sh` : bootstrap a local Ubuntu Jenkins host for this project
- `scripts/bootstrap-manifest.sh` : initialize and sync ST sources
- `scripts/build.sh` : configure environment and run BitBake
- `scripts/archive-artifacts.sh` : copy useful outputs to `out/`
- `scripts/build-container-image.sh` : build the local STM32/Yocto container image
- `scripts/run-container-build.sh` : run the project build flow inside the local container image
- `scripts/check-host-deps.sh` : quick host tooling check
- `containers/stm32mp-yocto/` : container definition for the ST/OpenSTLinux build environment
- `jenkins/Jenkinsfile` : Jenkins pipeline definition
- `docs/` : design and implementation notes

## Shared Yocto cache

By default the project uses a repo-local cache layout:
- downloads: `${PROJECT_ROOT}/.yocto-cache/downloads`
- sstate: `${PROJECT_ROOT}/.yocto-cache/sstate-cache`

You can override these paths with environment variables before running the scripts or from Jenkins job configuration:

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
- the generated ST default `bblayers.conf` template does not enable all required `meta-openembedded` dependency layers for this setup, so the wrapper normalizes `bblayers.conf` and patches in `meta-oe` and `meta-python` using template-relative layer entries only
- the valid machine identifier in the ST manifest is `stm32mp13-disco`; `stm32mp135f-dk` is the board name, not the Yocto `MACHINE` value used by this release
- if an existing build directory contains a mismatched previous `DISTRO` or `MACHINE`, the wrapper archives it automatically and recreates a clean ST build directory for the requested target
- for CI use, the wrapper can export the upstream `EULA_<machine-without-dashes-or-dots>=1` variable automatically so the ST setup does not stop on an interactive EULA prompt

## Quick start

### Path A: local command-line build

#### 1. Go to the project directory

```bash
cd /path/to/yocto_deep_dive
```

#### 2. Install Ubuntu host dependencies

```bash
./scripts/install-host-deps-ubuntu.sh
```

This script installs the host packages required by the ST OpenSTLinux environment on Ubuntu.

#### 3. Check host tools

```bash
./scripts/check-host-deps.sh
```

#### 4. Fetch and sync the ST manifest

```bash
./scripts/bootstrap-manifest.sh
```

#### 5. Run the build

```bash
./scripts/build.sh
```

#### 6. Archive build outputs

```bash
./scripts/archive-artifacts.sh
```

### Path B: local containerized build on Ubuntu

This branch is introducing a portable local containerized build flow for the same ST `oe-manifest` target.

#### 1. Install container host prerequisites

```bash
./scripts/install-host-deps-container-ubuntu.sh
```

#### 2. Build the local image

```bash
./scripts/build-container-image.sh
```

#### 3. Run the build in the container

```bash
./scripts/run-container-build.sh
```

#### 4. Optional cache overrides

```bash
export SHARED_CACHE_ROOT=/absolute/path/to/shared-yocto-cache
export DL_DIR=/absolute/path/to/shared-yocto-cache/downloads
export SSTATE_DIR=/absolute/path/to/shared-yocto-cache/sstate-cache
export FORCE_DL_CACHEPREFIX=/absolute/path/to/shared-yocto-cache
export FORCE_SSTATE_CACHEPREFIX=/absolute/path/to/shared-yocto-cache
./scripts/run-container-build.sh
```

For more details:
- `docs/container-architecture.md`
- `docs/container-build-quickstart.md`

### Path C: local Jenkins build on Ubuntu

This repository is designed so a developer can clone it, read this README, prepare a local Jenkins host, create one Pipeline job from SCM, and run the build without editing tracked files.

#### 1. Clone the repository

```bash
git clone <repo-url>
cd yocto_deep_dive
```

#### 2. Bootstrap the local Jenkins host

Choose a shared cache location on your machine, then run:

```bash
./scripts/setup-jenkins-local-ubuntu.sh \
    --shared-cache-root /absolute/path/to/shared-yocto-cache
```

Example:

```bash
./scripts/setup-jenkins-local-ubuntu.sh \
    --shared-cache-root /srv/yocto-cache/shared
```

This script:
- installs Jenkins and required host packages
- enables and starts `jenkins.service`
- prepares reusable Yocto `downloads/` and `sstate-cache/`
- grants Jenkins access to the shared cache
- configures Jenkins Git trust for shared `downloads/git2` mirrors
- prints the exact remaining Jenkins UI configuration

#### 3. Open Jenkins

Default local URL:

```text
http://127.0.0.1:8080
```

#### 4. Label the node

For the built-in local node, add the label:

```text
yocto-linux
```

#### 5. Create the Pipeline job

Create a Jenkins Pipeline job with:
- job type: `Pipeline`
- definition: `Pipeline script from SCM`
- SCM: `Git`
- repository URL: this repository
- branch: your target branch
- script path: `jenkins/Jenkinsfile`

Example branch during bring-up:

```text
*/feature/yocto-autobuild-stm32mp135f-dk
```

#### 6. Configure cache environment variables in Jenkins

Set these either globally in Jenkins or at the job level:

```text
SHARED_CACHE_ROOT=/absolute/path/to/shared-yocto-cache
DL_DIR=/absolute/path/to/shared-yocto-cache/downloads
SSTATE_DIR=/absolute/path/to/shared-yocto-cache/sstate-cache
FORCE_DL_CACHEPREFIX=/absolute/path/to/shared-yocto-cache
FORCE_SSTATE_CACHEPREFIX=/absolute/path/to/shared-yocto-cache
```

Example:

```text
SHARED_CACHE_ROOT=/srv/yocto-cache/shared
DL_DIR=/srv/yocto-cache/shared/downloads
SSTATE_DIR=/srv/yocto-cache/shared/sstate-cache
FORCE_DL_CACHEPREFIX=/srv/yocto-cache/shared
FORCE_SSTATE_CACHEPREFIX=/srv/yocto-cache/shared
```

#### 7. Run the Jenkins job

Recommended parameters:
- `RUN_BUILD = true`
- `ARCHIVE_OUTPUTS = true`

#### 8. Expected success criteria

A successful Jenkins run should show:
- manifest bootstrap succeeds
- shared cache paths are printed
- `Prepare shared cache access` stage runs
- BitBake completes successfully
- artifacts are copied to `out/<timestamp>/`
- final status is `SUCCESS`

Validated reference result on the current local Ubuntu/Jenkins bring-up:
- full `core-image-minimal` Jenkins build succeeded
- `6456` tasks completed successfully
- artifacts were archived from the Jenkins workspace

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

Implementation note:
- `config/build.env` resolves the project root from the file location itself so the same scripts work both in a normal shell and inside Jenkins `sh` steps

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
- Prepare shared cache access
- Build
- Archive outputs

Jenkins implementation notes:
- the Environment validation stage mirrors the shell wrapper behavior, including ST EULA bypass handling, temporary `nounset` disable during `envsetup.sh`, and `bblayers.conf` normalization
- Jenkins can override cache locations through job-level environment variables without hardcoding machine-specific paths into the repository
- the pipeline self-configures Git `safe.directory` for the Jenkins user before the build so shared Yocto `downloads/git2` mirrors can be reused without repeated manual operator fixes on a local single-user Jenkins machine
- the Jenkinsfile intentionally does not enable SCM polling during bring-up; prefer manual runs now, then move to a webhook or explicit nightly schedule later

## ST EULA handling

For non-interactive CI runs, the wrapper exports the upstream envsetup bypass variable:

```bash
EULA_stm32mp13disco=1
```

The ST setup then writes the corresponding Yocto setting into `local.conf`:

```bash
ACCEPT_EULA_stm32mp13-disco = "1"
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
- `docs/container-architecture.md`
- `docs/container-build-quickstart.md`
- `docs/jenkins-company-setup.md`
- `docs/secure-boot-signing-strategy.md`
