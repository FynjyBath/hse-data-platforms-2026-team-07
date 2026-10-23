#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

step "Рендеринг hive-site.xml"
envsubst < "$(dirname "$0")/../conf/hive-site.xml.template" > "$HIVE_HOME/conf/hive-site.xml"
cat > "$HIVE_HOME/conf/hive-env.sh" <<ENV
export HADOOP_HOME=$HADOOP_HOME
export JAVA_HOME=$JAVA_HOME
export HADOOP_CLIENT_OPTS="-Xmx2048m \$HADOOP_CLIENT_OPTS"
ENV
info "Готово: $HIVE_HOME/conf/hive-site.xml, $HIVE_HOME/conf/hive-env.sh"
