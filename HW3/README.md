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

```

Нужен клиент Hadoop на edge-ноде в `~/hadoop` (путь задаётся в `config.env`), настроенный на `hdfs://team-07-nn:9000`.

## Проверка
`scripts/6_load_partitions.sh` загружает три партиции в `web_logs`, `scripts/7_check.sh` подключает два клиента beeline одновременно:

```
+-------------+------+
|     dt      | _c1  |
+-------------+------+
| 2026-10-20  | 2    |
| 2026-10-21  | 2    |
| 2026-10-22  | 2    |
+-------------+------+
| client-1 OK  | team  |
| client-2 OK  | team  |
```

Проблемы, найденные при запуске, описаны в `BUG_REPORT.md`.
