# ДЗ-4. Apache Spark на YARN

## Схема

| Узел | Роль |
|---|---|
| `team-07-en` | Spark 3.5.9 (драйвер, client mode), Hive Metastore, HiveServer2 |
| `team-07-nn` | NameNode, ResourceManager, NodeManager, DataNode |
| `team-07-00`, `team-07-01` | NodeManager, DataNode |

Spark установлен в `/opt/spark`, конфигурация клиента Hadoop в `/opt/spark/conf/hadoop`.

Библиотеки Spark загружены в HDFS, поэтому их не нужно передавать при каждом запуске.

## Запуск

Файлы на edge-ноде находятся в `/home/team/hw4-team07`:

```bash
ssh team@171.22.73.191
cd /home/team/hw4-team07
./deploy.sh
```

Параметры задаются в `config.env`. `deploy.sh` можно безопасно запускать повторно.

## Шаги

### 1. Установка и настройка Spark `scripts/1_install_spark.sh`

### 2. Запуск Hive Metastore и HiveServer2 `scripts/2_start_hive.sh`

### 3. Загрузка исходных данных в HDFS `scripts/3_load_data.sh`

### 4. Обработка в Spark `scripts/4_spark_job.sh` → `scripts/sales_job.py`

### 5. Чтение стандартным клиентом Hive `scripts/5_check_hive.sh`

## Результат на нашем кластере

Spark:

```
master=yarn application=application_1791747958150_0004 defaultFS=hdfs://team-07-nn:9000
rows: raw=200000 clean=197938
+---------------------+
|partition            |
+---------------------+
|order_date=2026-10-01|
|...                  |
|order_date=2026-10-07|
+---------------------+
```

Приложение `hw4-sales` в ResourceManager: `FINISHED / SUCCEEDED`.

Hive (`beeline -u jdbc:hive2://team-07-en:10000/default`):

```
+-------------+---------+--------------+
| order_date  | orders  |   revenue    |
+-------------+---------+--------------+
| 2026-10-01  | 28425   | 10817839.61  |
| 2026-10-02  | 28791   | 10899482.21  |
| 2026-10-03  | 27898   | 10788863.37  |
| 2026-10-04  | 28236   | 10971210.10  |
| 2026-10-05  | 28184   | 10912898.27  |
| 2026-10-06  | 28047   | 10765266.83  |
| 2026-10-07  | 28357   | 10909493.98  |
+-------------+---------+--------------+
```

Сумма заказов по партициям в Hive (197 938) совпадает с числом валидных строк, которое посчитал Spark. `DESCRIBE FORMATTED hw4.sales_daily` показывает `EXTERNAL_TABLE`, `ParquetHiveSerDe` и партиционирование по `order_date date`.
