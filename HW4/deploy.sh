#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/scripts"
./1_install_spark.sh
./2_start_hive.sh
./3_load_data.sh
./4_spark_job.sh
./5_check_hive.sh
