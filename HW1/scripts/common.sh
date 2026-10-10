# Общие настройки и функции для всех шагов. Подключается через source.

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
set -a
source "$ROOT/config.env"
set +a

NODES=$(printf '%s\n' $NAMENODE $DATANODES | awk '!seen[$0]++')

SSH_OPTS=(-i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

run() {
    local host=$1
    shift
    local script
    script=$(
        echo 'set -euo pipefail'
        cat "$ROOT/config.env"
        for var in "$@"; do
            printf '%s=%q\n' "${var%%=*}" "${var#*=}"
        done
        cat
    )
    ssh -n "${SSH_OPTS[@]}" "$SSH_USER@$host" sudo -n bash -c "$(printf '%q' "$script")"
}

step() {
    echo
    echo "=== $*"
}
