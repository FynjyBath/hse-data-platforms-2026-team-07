#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
step 'Запуск ResourceManager и JobHistoryServer'
run "$NAMENODE" <<'REMOTE'
for pair in 'yarn resourcemanager' 'mapred historyserver'; do
    read -r tool daemon <<< "$pair"
    if sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/$tool" --daemon status "$daemon"; then
        sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/$tool" --daemon stop "$daemon"
    fi
    sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/$tool" --daemon start "$daemon"
done
REMOTE
for node in $NODES; do
    step "$node: запуск NodeManager"
    run "$node" <<'REMOTE'
if sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" --daemon status nodemanager; then
    sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" --daemon stop nodemanager
fi
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/yarn" --daemon start nodemanager
REMOTE
done
step 'Ожидание регистрации трёх NodeManager (до 90 секунд)'
for attempt in $(seq 1 30); do
    count=$(run "$NAMENODE" <<'REMOTE'
curl -fsS http://team-07-nn:8088/ws/v1/cluster/metrics 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["clusterMetrics"]["activeNodes"])' || echo 0
REMOTE
)
    if [[ $count == 3 ]]; then echo '3 NodeManager зарегистрированы'; exit 0; fi
    sleep 3
done
echo 'NodeManager не зарегистрировались вовремя' >&2
exit 1
