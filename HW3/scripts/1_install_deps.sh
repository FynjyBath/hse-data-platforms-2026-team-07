#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"

step "Установка Java 11 и PostgreSQL"
sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -qq openjdk-11-jdk postgresql postgresql-contrib
sudo systemctl enable --now postgresql

step "Создание БД и пользователя Metastore"
sudo -u postgres psql <<SQL
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='${POSTGRES_USER}') THEN
    CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
  END IF;
END \$\$;
SELECT 'CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='${POSTGRES_DB}')\gexec
SQL
