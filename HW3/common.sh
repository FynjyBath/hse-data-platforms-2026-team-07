#!/usr/bin/env bash
set -euo pipefail

# подгружаем настройки из конфига
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
source "$ROOT/config.env"
set +a
export PATH="$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH"

# функции для красивого вывода в консоль
step() { echo -e "\n=== $* ==="; }
info() { echo "[INFO] $*"; }
