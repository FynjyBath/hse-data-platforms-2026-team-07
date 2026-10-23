#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

step "Инициализация схемы Metastore в PostgreSQL"
"$HIVE_HOME/bin/schematool" -dbType postgres -initSchema || \
  info "Схема уже существует — продолжаем"
