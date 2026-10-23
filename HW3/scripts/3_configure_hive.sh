#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

step "Рендеринг hive-site.xml"
envsubst < "$(dirname "$0")/../conf/hive-site.xml.template" > "$HIVE_HOME/conf/hive-site.xml"
info "Готово: $HIVE_HOME/conf/hive-site.xml"
