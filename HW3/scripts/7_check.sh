#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

step "Проверка multi-client: два параллельных beeline"
BEELINE=("$HIVE_HOME/bin/beeline" -u "jdbc:hive2://${METASTORE_HOST}:${HIVESERVER2_PORT}/default" -n team --silent=true)

"${BEELINE[@]}" -e "SELECT 'client-1 OK', current_user();" &
P1=$!
"${BEELINE[@]}" -e "SELECT 'client-2 OK', current_user();" &
P2=$!
wait $P1; wait $P2

step "Порты и процессы"
ss -tlnp | grep -E ":$METASTORE_PORT|:$HIVESERVER2_PORT"
