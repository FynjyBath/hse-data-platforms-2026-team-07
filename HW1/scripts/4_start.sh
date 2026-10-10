#!/usr/bin/env bash
# Шаг 4. Форматирование NameNode и запуск HDFS.
source "$(dirname "$0")/common.sh"

step "$NAMENODE: запуск HDFS"
run "$NAMENODE" <<'EOF'
as_hadoop() { sudo -iu "$HADOOP_USER" "$@"; }

if [ ! -f "$DATA_DIR/namenode/current/VERSION" ]; then
    as_hadoop env HADOOP_ROOT_LOGGER=WARN,console hdfs namenode -format -nonInteractive
    echo "NameNode отформатирована"
fi

# Перезапуск, чтобы при повторном прогоне применилась новая конфигурация
as_hadoop stop-dfs.sh
as_hadoop start-dfs.sh
EOF
