#!/usr/bin/env bash
# Запускать на edge-ноде.
# Повторный запуск безопасен, выполненные шаги пропускаются, HDFS перезапускается.
set -euo pipefail
cd "$(dirname "$0")/scripts"

./1_prepare.sh
./2_install.sh
./3_configure.sh
./4_start.sh
./5_check.sh
