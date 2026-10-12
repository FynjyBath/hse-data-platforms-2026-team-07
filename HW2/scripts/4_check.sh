#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
step 'Процессы'
for node in $NODES; do
    run "$node" <<'REMOTE'
hostname
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" --daemon status nodemanager
if [[ $(hostname -s) == "$NAMENODE" ]]; then
    sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" --daemon status resourcemanager
    sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/mapred" --daemon status historyserver
fi
sudo -iu "$HADOOP_USER" jps
sha256sum -c "$BACKUP_ROOT/initial/hdfs.sha256"
REMOTE
done
step 'HDFS и зарегистрированные узлы YARN'
run "$NAMENODE" <<'REMOTE'
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hdfs" dfsadmin -report
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" node -list -all
curl -fsS http://team-07-nn:8088/ws/v1/cluster/metrics | python3 -c 'import json,sys; m=json.load(sys.stdin)["clusterMetrics"]; print(json.dumps(m,indent=2)); assert m["activeNodes"] == 3 and m["unhealthyNodes"] == 0'
REMOTE
step 'HTTP всех внутренних интерфейсов'
for address in team-07-nn:8088/cluster team-07-nn:19888/jobhistory team-07-nn:9870/dfshealth.html team-07-nn:9868/ team-07-nn:8042/node team-07-00:8042/node team-07-01:8042/node team-07-nn:9864/datanode.html team-07-00:9864/datanode.html team-07-01:9864/datanode.html; do
    code=$(curl -fsSL -o /dev/null -w '%{http_code}' "http://$address")
    [[ $code == 200 ]] || exit 1
    echo "$address HTTP $code"
done
step 'Пароль на внешнем прокси'
[[ $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8088/cluster) == 401 ]]
echo 'Без пароля: HTTP 401'
echo 'Проверка с паролем и внешнего доступа выполняется с компьютера вне кластера.'
