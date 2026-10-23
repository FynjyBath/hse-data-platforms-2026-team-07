#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

mkdir -p /tmp/hive-logs

step "Каталоги Hive в HDFS"
HADOOP_USER_NAME=hadoop hdfs dfs -mkdir -p /tmp/hive "$HDFS_WAREHOUSE_DIR" "/user/$USER"
HADOOP_USER_NAME=hadoop hdfs dfs -chmod 777 /tmp/hive "$HDFS_WAREHOUSE_DIR" "/user/$USER"

for service in hiveserver2 metastore; do
  pkill -f -- "/java .*-Dproc_$service " && while pgrep -f -- "/java .*-Dproc_$service " >/dev/null; do sleep 1; done || true
done

step "Запуск Hive Metastore (thrift :$METASTORE_PORT)"
nohup "$HIVE_HOME/bin/hive" --service metastore > /tmp/hive-logs/metastore.log 2>&1 < /dev/null &
echo $! > /tmp/hive-logs/metastore.pid

step "Запуск HiveServer2 (:$HIVESERVER2_PORT)"
nohup "$HIVE_HOME/bin/hive" --service hiveserver2 > /tmp/hive-logs/hiveserver2.log 2>&1 < /dev/null &
echo $! > /tmp/hive-logs/hiveserver2.pid

info "Ждём, пока поднимутся порты (до 5 минут)..."
for _ in $(seq 150); do
  [ "$(ss -tln | grep -cE ":($METASTORE_PORT|$HIVESERVER2_PORT) ")" -eq 2 ] && break
  sleep 2
done
[ "$(ss -tln | grep -cE ":($METASTORE_PORT|$HIVESERVER2_PORT) ")" -eq 2 ] || {
  echo "Порты не поднялись, смотри логи:"; tail -n 40 /tmp/hive-logs/*.log; exit 1;
}
ss -tlnp | grep -E ":($METASTORE_PORT|$HIVESERVER2_PORT) "
