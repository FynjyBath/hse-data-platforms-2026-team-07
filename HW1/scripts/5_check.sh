#!/usr/bin/env bash
# Шаг 5. Проверка целостности кластера.
source "$(dirname "$0")/common.sh"

errors=0
fail() {
    echo "ОШИБКА: $*"
    errors=$((errors + 1))
}

step "Процессы HDFS на узлах"
for node in $NODES; do
    procs=$(run "$node" <<<'sudo -iu "$HADOOP_USER" jps' | awk '$2 != "Jps" {print $2}' | sort | xargs)
    echo "$node: $procs"
    want=""
    if [ "$node" = "$NAMENODE" ]; then
        want="NameNode SecondaryNameNode"
    fi
    if [[ " $DATANODES " == *" $node "* ]]; then
        want="$want DataNode"
    fi
    for proc in $want; do
        [[ " $procs " == *" $proc "* ]] || fail "$node: не запущен $proc"
    done
done

step "DataNode в отчёте NameNode"
expected=$(wc -w <<< "$DATANODES")
report=$(run "$NAMENODE" EXPECTED="$expected" <<'EOF'
as_hadoop() { sudo -iu "$HADOOP_USER" "$@"; }
as_hadoop hdfs dfsadmin -safemode wait >/dev/null
for i in $(seq 30); do
    live=$(as_hadoop hdfs dfsadmin -report -live | grep -oP 'Live datanodes \(\K\d+')
    [ "$live" -ge "$EXPECTED" ] && break
    sleep 2
done
as_hadoop hdfs dfsadmin -report
EOF
)
grep -E '^(Live|Dead|Decommissioning|Entering maintenance|In maintenance) datanodes|^Name:' <<< "$report"
live=$(grep -oP 'Live datanodes \(\K\d+' <<< "$report")
dead=$(grep -oP 'Dead datanodes \(\K\d+' <<< "$report" || echo 0)
[ "$live" -eq "$expected" ] || fail "живых DataNode $live, ожидалось $expected"
[ "$dead" -eq 0 ] || fail "мёртвых DataNode: $dead"

step "Веб-интерфейс NameNode"
if curl -fs -o /dev/null "http://$NAMENODE:9870/"; then
    echo "http://$NAMENODE:9870 отвечает"
else
    fail "http://$NAMENODE:9870 не отвечает"
fi

step "Запись тестового файла (реплик: $REPLICATION)"
fsck=$(run "$NAMENODE" <<'EOF'
as_hadoop() { sudo -iu "$HADOOP_USER" "$@"; }
file=/hdfs-check-$(date +%s).txt
as_hadoop bash -c "echo hello | hdfs dfs -put - $file"
as_hadoop hdfs fsck "$file" -files -blocks -locations 2>/dev/null
as_hadoop hdfs dfs -rm -f -skipTrash "$file" >/dev/null
EOF
)
replicas=$(grep -o 'DatanodeInfoWithStorage' <<< "$fsck" | wc -l || true)
echo "реплик блока: $replicas"
grep -q 'Status: HEALTHY' <<< "$fsck" || fail "fsck: файл не в статусе HEALTHY"
[ "$replicas" -eq "$REPLICATION" ] || fail "реплик $replicas, ожидалось $REPLICATION"

step "Ошибки в логах с последнего запуска"
for node in $NODES; do
    log_errors=$(run "$node" <<'EOF'
for log in "$HADOOP_HOME"/logs/*.log; do
    tac "$log" | sed '/STARTUP_MSG: Starting/q' | tac | grep -E ' (ERROR|FATAL) ' || true
done
EOF
)
    if [ -n "$log_errors" ]; then
        fail "$node: ошибки в логах"
        echo "$log_errors"
    else
        echo "$node: ошибок нет"
    fi
done

echo
if [ "$errors" -eq 0 ]; then
    echo "Кластер исправен"
else
    echo "Найдено проблем: $errors"
    exit 1
fi
