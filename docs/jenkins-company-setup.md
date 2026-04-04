# Jenkins company-style setup

## Objective

Provide a professional first implementation where:
- every commit can be validated automatically
- the pipeline is readable in Jenkins stage view
- source bootstrap, environment validation, build, and archival are separated clearly
- secure-boot private keys are not yet exposed to CI
- a new developer can reproduce the setup from the repository README and helper scripts without relying on undocumented operator memory

## Recommended Jenkins model

### 1. Use Pipeline from SCM

Configure one Jenkins job as:
- job type: Pipeline
- definition: Pipeline script from SCM
- repository: this project repository
- script path: `jenkins/Jenkinsfile`

This gives versioned CI logic and proper stage visualization.

For a local Ubuntu laptop/workstation bring-up, use the repository helper:
- `scripts/setup-jenkins-local-ubuntu.sh`

That script prepares the host, Jenkins service, shared cache permissions, and Jenkins Git trust. The remaining job creation stays explicit in the Jenkins UI so the repository remains portable across machines and organizations.

### 2. Agent model

For now:
- one dedicated Linux agent label: `yocto-linux`
- runs directly on the PC or on a controlled build node
- persistent shared cache paths reused across builds
- for this local single-user Jenkins machine, the pipeline self-configures Git `safe.directory='*'` before build execution so BitBake can safely reuse shared `downloads/git2` mirrors without manual intervention

### 3. Per-commit validation

Recommended policy:
- each push to the main development branch triggers the pipeline
- each merge request / pull request should run the same validation pipeline before merge

In the first phase, per-commit validation means:
- repository checkout works
- host dependencies exist
- ST manifest bootstrap works
- environment setup works
- Yocto build runs successfully

## Visualization

The current Jenkinsfile is designed for clear Stage View / Blue Ocean style visualization:
- Checkout
- Host validation
  - Tooling
  - Config
- Source bootstrap
- Environment validation
- Build
- Archive outputs

That is already a clean professional first shape.

## What to add later for a stronger company implementation

### Near term
- webhook-triggered builds instead of polling
- branch-specific policies
- separate quick-check vs full-build jobs
- log retention and artifact retention tuning
- automatic naming/version stamping

Note:
- SCM polling is intentionally not enabled in the repository Jenkinsfile during bring-up
- use manual runs now, then switch to an explicit nightly Jenkins trigger or SCM webhook after stabilization

### Release quality
- signed release pipeline separate from development CI
- manual approval gate for release promotion
- artifact repository publication
- test report publication
- build metadata export

### Governance
- protected branches
- required CI status before merge
- restricted Jenkins credentials use
- audit of who can change pipeline/job definitions

## Strong recommendation

Do not put secure-boot private keys into this first per-commit validation pipeline.

A company-style implementation separates:
- continuous integration for every commit
- controlled release signing for approved artifacts only
