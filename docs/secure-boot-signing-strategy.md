# Secure boot and signing strategy

## Current decision

Do not inject private secure-boot keys into the first autobuild pipeline.

That is intentional.

## Reasoning

For a first professional implementation, the build path and the signing path should be separated.

Unsigned CI build path:
- checks out source
- builds artifacts
- verifies reproducibility and functional stability
- archives artifacts and logs

Restricted signing path:
- signs only approved release artifacts
- runs on a dedicated trusted node or with hardware-backed key storage
- is not available to every developer branch build

## Recommended progression

### Step 1
Implement unsigned autobuild only.

### Step 2
Define what must be signed exactly:
- TF-A / FIP
- U-Boot
- FIT image
- update bundle
- other STM32MP secure-boot artifacts

### Step 3
Choose signing location:
- best: dedicated signer or HSM / PKCS#11
- acceptable starter: dedicated Jenkins node with strict filesystem and job controls
- avoid: putting production private keys on general-purpose build workers

### Step 4
Restrict signing triggers:
- protected branches only
- version tags only
- manual approval before signing

## What not to do

Do not:
- store private keys in git
- print key material in logs
- export private keys as broad environment variables
- allow untrusted branches to run signing stages
- mix early autobuild validation with production signing from day one

## Practical next milestone

After the first Yocto autobuild works reliably, the next engineering step is to map the exact STM32MP135 secure-boot chain you use and design a separate release-signing flow around it.
