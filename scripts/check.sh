#!/usr/bin/env bash
# Run the GameCore tests, then (optionally) build and install with xtool.
#   scripts/check.sh          tests only
#   scripts/check.sh --dev    tests, then `xtool dev` (build + install on phone)
set -euo pipefail
cd "$(dirname "$0")/.."

swift test

if [[ "${1:-}" == "--dev" ]]; then
    xtool dev
fi
