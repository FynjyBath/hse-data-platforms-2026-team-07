#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
mkdir -p "$ROOT/evidence"
run "$NAMENODE" <<'REMOTE' | tee "$ROOT/evidence/wordcount.txt"
run_id=$(date -u +%Y%m%dT%H%M%SZ)
base=/user/hadoop/hw2-wordcount-$run_id
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf 'hadoop yarn hadoop\nyarn mapreduce\n' > "$tmp"
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p "$base/input"
chmod 644 "$tmp"
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hdfs" dfs -put "$tmp" "$base/input/text.txt"
jar=$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.3.jar
echo "TEST_PATH=$base"
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hadoop" jar "$jar" wordcount -Dmapreduce.job.reduces=1 "$base/input" "$base/output"
result=$(sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hdfs" dfs -cat "$base/output/part-r-00000")
printf '%s\n' "$result"
expected=$(printf 'hadoop\t2\nmapreduce\t1\nyarn\t2')
[[ $result == "$expected" ]] || { echo 'Неверный результат WordCount'; exit 1; }
sudo -iu "$HADOOP_USER" "$HADOOP_HOME/bin/hdfs" dfs -test -e "$base/output/_SUCCESS"
echo 'WORDCOUNT_OK'
REMOTE
