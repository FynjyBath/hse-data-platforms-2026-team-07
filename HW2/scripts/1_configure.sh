#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
for node in $NODES; do
    step "$node: резервная копия и конфигурация YARN"
    memory=2048
    [[ $node != "$NAMENODE" ]] || memory=1024
    yarn_conf=$(sed "s|<name>yarn.nodemanager.resource.memory-mb</name><value>2048</value>|<name>yarn.nodemanager.resource.memory-mb</name><value>$memory</value>|" "$ROOT/conf/yarn-site.xml")
    run "$node" "YARN_CONF=$yarn_conf" "MAPRED_CONF=$(cat "$ROOT/conf/mapred-site.xml")" <<'REMOTE'
conf=$HADOOP_HOME/etc/hadoop
backup=$BACKUP_ROOT/initial
install -d -m 700 "$backup"
if [[ ! -e $backup/config.complete ]]; then
    for name in yarn-site.xml mapred-site.xml yarn-env.sh mapred-env.sh; do
        cp -a "$conf/$name" "$backup/$name"
    done
    sha256sum "$conf/core-site.xml" "$conf/hdfs-site.xml" "$conf/hadoop-env.sh" > "$backup/hdfs.sha256"
    date -Is > "$backup/config.complete"
fi
printf '%s\n' "$YARN_CONF" > "$conf/yarn-site.xml"
printf '%s\n' "$MAPRED_CONF" > "$conf/mapred-site.xml"
for name in yarn-env.sh mapred-env.sh; do
    sed -i '/# BEGIN TEAM07 HW2/,/# END TEAM07 HW2/d' "$conf/$name"
done
cat >> "$conf/yarn-env.sh" <<'ENV'
# BEGIN TEAM07 HW2
export YARN_RESOURCEMANAGER_HEAPSIZE=256
export YARN_NODEMANAGER_HEAPSIZE=256
# END TEAM07 HW2
ENV
cat >> "$conf/mapred-env.sh" <<'ENV'
# BEGIN TEAM07 HW2
export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=256
# END TEAM07 HW2
ENV
chown "$HADOOP_USER:$HADOOP_USER" "$conf/yarn-site.xml" "$conf/mapred-site.xml" "$conf/yarn-env.sh" "$conf/mapred-env.sh"
install -d -m 755 -o "$HADOOP_USER" -g "$HADOOP_USER" "$YARN_DATA" "$YARN_DATA/local" "$YARN_DATA/logs"
sha256sum -c "$backup/hdfs.sha256"
REMOTE
done
step 'HDFS: каталоги истории и агрегированных логов'
run "$NAMENODE" <<'REMOTE'
as_hadoop() { sudo -iu "$HADOOP_USER" "$@"; }
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p /mr-history/tmp /mr-history/done /tmp/team07-yarn-logs
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -chmod 1777 /mr-history/tmp /tmp/team07-yarn-logs
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -chmod 750 /mr-history/done
REMOTE
