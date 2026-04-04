#!/usr/bin/env bash
set -euo pipefail

missing=0
for cmd in git repo python3 gcc g++ make tar gzip bzip2 xz sed awk diffstat chrpath cpio file unzip rsync; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "MISSING: $cmd"
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    echo "Host dependency check failed"
    exit 1
fi

echo "Host dependency check passed"
