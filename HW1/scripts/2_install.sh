#!/usr/bin/env bash
# Шаг 2. Установка Hadoop.
source "$(dirname "$0")/common.sh"

archive=$HOME/$(basename "$HADOOP_URL")

step "Скачивание $(basename "$archive")"
if [ ! -f "$archive" ]; then
    curl -fL --progress-bar -o "$archive.part" "$HADOOP_URL"
    mv "$archive.part" "$archive"
fi
if ! curl -fsSL "$HADOOP_URL.sha512" | (cd "$(dirname "$archive")" && sha512sum -c -); then
    rm -f "$archive"
    echo "Контрольная сумма не совпала, архив удалён — запустите шаг ещё раз" >&2
    exit 1
fi

for node in $NODES; do
    step "$node: установка в $HADOOP_HOME"
    if run "$node" <<<'[ -x "$HADOOP_HOME/bin/hdfs" ]'; then
        echo "уже установлен"
        continue
    fi
    scp -q "${SSH_OPTS[@]}" "$archive" "$SSH_USER@$node:/tmp/"
    run "$node" ARCHIVE="/tmp/$(basename "$archive")" <<'EOF'
parent=$(dirname "$HADOOP_HOME")
mkdir -p "$parent"
rm -rf "$parent/hadoop-$HADOOP_VERSION"
tar -xzf "$ARCHIVE" -C "$parent"
mkdir -p "$parent/hadoop-$HADOOP_VERSION/logs"
chown -R "$HADOOP_USER:" "$parent/hadoop-$HADOOP_VERSION"
mv "$parent/hadoop-$HADOOP_VERSION" "$HADOOP_HOME"
rm -f "$ARCHIVE"
echo "установлен Hadoop $HADOOP_VERSION"
EOF
done
