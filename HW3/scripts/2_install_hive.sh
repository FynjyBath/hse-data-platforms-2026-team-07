#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

# качаем и распаковываем архив хайва
step "Скачивание Hive ${HIVE_VERSION}"
sudo mkdir -p /opt
if [ ! -d "$HIVE_HOME" ]; then
  sudo wget -q -O /tmp/hive.tar.gz "$HIVE_ARCHIVE_URL"
  sudo tar -xzf /tmp/hive.tar.gz -C /opt
  sudo mv "/opt/apache-hive-${HIVE_VERSION}-bin" "$HIVE_HOME"
fi
sudo chown -R "$USER":"$USER" "$HIVE_HOME"

# не забываем про jdbc драйвер для постгреса
step "Скачивание PostgreSQL JDBC"
[ -f "$HIVE_HOME/lib/postgresql.jar" ] || wget -q -O "$HIVE_HOME/lib/postgresql.jar" "$PG_JDBC_URL"

# прописываем пути в bashrc
grep -q 'HIVE_HOME' ~/.bashrc || cat >> ~/.bashrc <<RC
export HIVE_HOME=$HIVE_HOME
export PATH=\$HIVE_HOME/bin:\$PATH
RC
