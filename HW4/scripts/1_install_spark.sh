#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

archive=$HOME/$(basename "$SPARK_URL")
step "Скачивание $(basename "$archive")"
if [ ! -f "$archive" ]; then
    curl -fL --progress-bar -o "$archive.part" "$SPARK_URL"
    mv "$archive.part" "$archive"
fi
if ! curl -fsSL "$SPARK_URL.sha512" | (cd "$HOME" && sha512sum -c -); then
    rm -f "$archive"
    echo "Контрольная сумма не совпала, архив удалён — запустите шаг ещё раз" >&2
    exit 1
fi

step "Установка в $SPARK_HOME"
if [ ! -x "$SPARK_HOME/bin/spark-submit" ]; then
    unpacked=$(dirname "$SPARK_HOME")/$(basename "$archive" .tgz)
    sudo rm -rf "$unpacked"
    sudo tar -xzf "$archive" -C "$(dirname "$SPARK_HOME")"
    sudo mv "$unpacked" "$SPARK_HOME"
    sudo chown -R "$USER:" "$SPARK_HOME"
fi
"$SPARK_HOME/bin/spark-submit" --version 2>&1 | grep -m1 -o 'version [0-9.]*'

step "Конфигурация Spark"
mkdir -p "$SPARK_HOME/conf/hadoop"
envsubst < "$ROOT/conf/core-site.xml" > "$SPARK_HOME/conf/hadoop/core-site.xml"
envsubst < "$ROOT/conf/yarn-site.xml" > "$SPARK_HOME/conf/hadoop/yarn-site.xml"
envsubst < "$ROOT/conf/spark-defaults.conf" > "$SPARK_HOME/conf/spark-defaults.conf"
cat > "$SPARK_HOME/conf/spark-env.sh" <<EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_CONF_DIR=$SPARK_HOME/conf/hadoop
EOF
cat "$SPARK_HOME/conf/spark-defaults.conf"

step "Библиотеки Spark в HDFS: $SPARK_ARCHIVE"
if ! hdfs dfs -test -e "$SPARK_ARCHIVE"; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    "$JAVA_HOME/bin/jar" cf0 "$tmp/libs.jar" -C "$SPARK_HOME/jars" .
    hdfs dfs -mkdir -p "$(dirname "$SPARK_ARCHIVE")"
    hdfs dfs -put -f "$tmp/libs.jar" "$SPARK_ARCHIVE"
fi
hdfs dfs -ls "$SPARK_ARCHIVE"
