# HW3 — Apache Hive 4.0.0-alpha-2: remote Metastore + HiveServer2

## Архитектура
- PostgreSQL хранит метаданные Metastore.
- Hive Metastore работает как отдельный thrift-сервис (`thrift://team-07-en:9083`).
- HiveServer2 слушает `0.0.0.0:10000`, поэтому несколько клиентов могут подключаться одновременно (embedded Derby так не умеет).
- Данные таблиц лежат в HDFS (`/user/hive/warehouse`).

## Запуск
```bash
cd HW3
./deploy.sh

