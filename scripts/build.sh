#!/usr/bin/env bash
set -e

# Default: do not use ML-DSA
USE_MLDSA=${1:-false}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build Docker image
docker build \
    --build-arg USE_MLDSA="$USE_MLDSA" \
    -t quantum-safe-web-server \
    "$SCRIPT_DIR/.."
