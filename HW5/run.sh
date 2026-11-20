#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}"
export SPARK_HOME="${SPARK_HOME:-/opt/spark}"
export HADOOP_HOME="${HADOOP_HOME:-$HOME/hadoop}"
export HIVE_HOME="${HIVE_HOME:-/opt/hive}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-$SPARK_HOME/conf/hadoop}"

# Each checkout gets its own local Prefect metadata store.
export PREFECT_HOME="$PWD/.prefect"
export PREFECT_SERVER_ALLOW_EPHEMERAL_MODE=true
export PREFECT_SERVER_ANALYTICS_ENABLED=false
export PREFECT_CLIENT_TELEMETRY_ENABLED=false
unset PREFECT_API_URL PREFECT_API_KEY

if [[ ! -x .venv/bin/pip ]]; then
    python3 -m venv .venv
fi
if ! .venv/bin/python -c 'from prefect.server.api.server import SubprocessASGIServer' >/dev/null 2>&1; then
    .venv/bin/pip install --disable-pip-version-check -r requirements.txt
fi

exec flock -n .prefect-hw5.lock .venv/bin/python flow.py "$@"
