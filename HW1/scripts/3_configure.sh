#!/usr/bin/env bash
# Шаг 3. Переменные окружения и конфигурация HDFS.
source "$(dirname "$0")/common.sh"

render() {
    envsubst '$NAMENODE $DATA_DIR $REPLICATION' < "$ROOT/conf/$1"
}

for node in $NODES; do
    step "$node: конфигурация"
    run "$node" CORE_SITE="$(render core-site.xml)" HDFS_SITE="$(render hdfs-site.xml)" <<'EOF'
java_home=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")

cat > /etc/profile.d/hadoop.sh <<PROFILE
export JAVA_HOME=$java_home
export HADOOP_HOME=$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
PROFILE

conf=$HADOOP_HOME/etc/hadoop
echo "$CORE_SITE" > "$conf/core-site.xml"
echo "$HDFS_SITE" > "$conf/hdfs-site.xml"
printf '%s\n' $DATANODES > "$conf/workers"

# start-dfs.sh запускает демоны по SSH без профиля, поэтому JAVA_HOME задаём здесь
sed -i '/^export JAVA_HOME=/d' "$conf/hadoop-env.sh"
echo "export JAVA_HOME=$java_home" >> "$conf/hadoop-env.sh"

echo "fs.defaultFS = $(sudo -iu "$HADOOP_USER" hdfs getconf -confKey fs.defaultFS)"
EOF
done
