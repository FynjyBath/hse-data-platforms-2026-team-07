#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
chmod +x scripts/*.sh
./scripts/1_install_deps.sh
./scripts/2_install_hive.sh
./scripts/3_configure_hive.sh
./scripts/4_init_schema.sh
./scripts/5_start_services.sh
./scripts/6_load_partitions.sh
./scripts/7_check.sh
echo "=== HW3 развёрнут ==="
