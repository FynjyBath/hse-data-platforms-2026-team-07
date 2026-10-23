#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
set -a
source "$ROOT/config.env"
set +a
hdfs() { "$HADOOP_HOME/bin/hdfs" "$@"; }
beeline() { "$HIVE_HOME/bin/beeline" -u "$HIVE_JDBC" -n "$USER" --silent=true "$@"; }
step() { printf '\n=== %s\n' "$*"; }
