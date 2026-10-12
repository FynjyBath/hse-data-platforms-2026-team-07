#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/config.env"
SSH_OPTS=(-i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new)
run() {
    local host=$1
    shift
    {
        echo 'set -euo pipefail'
        for var in HADOOP_HOME HADOOP_USER YARN_DATA BACKUP_ROOT NAMENODE; do
            printf '%s=%q\n' "$var" "${!var}"
        done
        for assignment in "$@"; do
            printf '%s=%q\n' "${assignment%%=*}" "${assignment#*=}"
        done
        cat
    } | ssh "${SSH_OPTS[@]}" "$SSH_USER@$host" sudo -n bash -s
}
step() { printf '\n=== %s\n' "$*"; }
