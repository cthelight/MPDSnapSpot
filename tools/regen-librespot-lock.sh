#!/usr/bin/env bash
# Regenerate the pinned Cargo.lock for a given librespot version, so the
# Docker build stays reproducible (it installs with --locked).
#
# Usage:  LIBRESPOT_VERSION=0.8.0 ./tools/regen-librespot-lock.sh
#
# The lockfile is written to vendor/librespot-<version>/Cargo.lock.
# If a fresh resolution fails to compile (upstream dependency drift), pin the
# offending crate, e.g.:  cargo update -p <crate> --precise <version>
set -euo pipefail

: "${LIBRESPOT_VERSION:?set LIBRESPOT_VERSION, e.g. 0.8.0}"

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${HERE}/vendor/librespot-${LIBRESPOT_VERSION}"
mkdir -p "$OUT_DIR"

docker run --rm -v "${OUT_DIR}:/out" debian:trixie-slim bash -euo pipefail -c '
    set -e
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends ca-certificates curl build-essential pkg-config libasound2-dev libssl-dev >/dev/null
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --profile minimal
    . /root/.cargo/env
    curl -fsSL -o /tmp/lr.tgz "https://github.com/librespot-org/librespot/archive/refs/tags/v'"${LIBRESPOT_VERSION}"'.tar.gz"
    tar -xzf /tmp/lr.tgz -C /tmp
    cd "/tmp/librespot-'"${LIBRESPOT_VERSION}"'"
    cargo generate-lockfile
    cp Cargo.lock /out/Cargo.lock
    echo "Wrote /out/Cargo.lock"
'
echo "Done. Verify the Docker build still compiles with: docker build . (or make build)"
