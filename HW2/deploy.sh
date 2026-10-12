#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
bash "$ROOT/scripts/1_configure.sh"
bash "$ROOT/scripts/2_start.sh"
bash "$ROOT/scripts/3_publish.sh"
bash "$ROOT/scripts/4_check.sh"
echo 'Развёртывание завершено. WordCount: bash scripts/5_wordcount.sh'
