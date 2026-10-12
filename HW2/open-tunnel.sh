#!/usr/bin/env bash
set -euo pipefail
key=${1:?Укажите путь к личному приватному SSH-ключу: bash open-tunnel.sh ~/.ssh/имя_ключа}
opts=(-i "$key" -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3)
for port in 8088 19888 9870 9868 18041 18042 18043 19861 19862 19863; do
    opts+=(-L "127.0.0.1:$port:127.0.0.1:$port")
done
echo 'После подключения откройте http://127.0.0.1:8088/cluster (пароль веб-доступа нужен отдельно).'
exec ssh "${opts[@]}" -N team@171.22.73.191
