#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/config.env"

step() { echo -e "\n=== $* ==="; }
info() { echo "[INFO] $*"; }
