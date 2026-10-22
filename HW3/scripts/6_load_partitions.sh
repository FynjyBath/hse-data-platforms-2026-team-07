#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

BEELINE=("$HIVE_HOME/bin/beeline" -u "jdbc:hive2://${METASTORE_HOST}:${HIVESERVER2_PORT}/default" -n team --silent=true)

step "Создание партиционированной таблицы web_logs"
"${BEELINE[@]}" -e "CREATE TABLE IF NOT EXISTS web_logs (ip STRING, url STRING) PARTITIONED BY (dt STRING) STORED AS TEXTFILE;"

step "Подготовка данных в HDFS"
TMP=$(mktemp -d)
for dt in 2026-10-20 2026-10-21 2026-10-22; do
  mkdir -p "$TMP/dt=$dt"
  printf '10.0.0.1,/index\n10.0.0.2,/about\n' > "$TMP/dt=$dt/part-00000"
done
hdfs dfs -mkdir -p /user/team/data/logs
hdfs dfs -put -f "$TMP"/dt=* /user/team/data/logs/ || true
rm -rf "$TMP"

step "Автоматическая загрузка партиций"
for dir in $(hdfs dfs -ls /user/team/data/logs | awk '/dt=/{print $NF}'); do
  dt=$(basename "$dir" | cut -d= -f2)
  info "Загружаем партицию dt=$dt из $dir"
  "${BEELINE[@]}" -e "LOAD DATA INPATH '$dir' INTO TABLE web_logs PARTITION (dt='$dt');"
done

step "Проверка партиций"
"${BEELINE[@]}" -e "SHOW PARTITIONS web_logs; SELECT dt, count(*) FROM web_logs GROUP BY dt;"
