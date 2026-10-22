#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

mkdir -p /tmp/hive-logs

step "Запуск Hive Metastore (thrift :$METASTORE_PORT)"
nohup "$HIVE_HOME/bin/hive" --service metastore > /tmp/hive-logs/metastore.log 2>&1 &
echo $! > /tmp/hive-logs/metastore.pid

step "Запуск HiveServer2 (:$HIVESERVER2_PORT)"
nohup "$HIVE_HOME/bin/hive" --service hiveserver2 > /tmp/hive-logs/hiveserver2.log 2>&1 &
echo $! > /tmp/hive-logs/hiveserver2.pid

info "Ждём 20 секунд, пока поднимутся порты..."
sleep 20
ss -tlnp | grep -E ":$METASTORE_PORT|:$HIVESERVER2_PORT" || {
  echo "Порты не поднялись, смотри логи:"; tail -n 40 /tmp/hive-logs/*.log; exit 1;
}
