#!/usr/bin/env bash
set -euo pipefail

# подгружаем настройки из конфига
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/config.env"

# функции для красивого вывода в консоль
step() { echo -e "\n=== $* ==="; }
info() { echo "[INFO] $*"; }
