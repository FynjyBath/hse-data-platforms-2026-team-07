# ДЗ-2

## Схема кластера

| Узел | IP | Роль |
|---|---|---|
| `team-07-en` | 10.7.0.10 | edge-нода, Nginx |
| `team-07-nn` | 10.7.0.11 | NameNode, SecondaryNameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer |
| `team-07-00` | 10.7.0.12 | DataNode, NodeManager |
| `team-07-01` | 10.7.0.13 | DataNode, NodeManager |

- Hadoop 3.4.3 и OpenJDK 11, пользователь `hadoop`.
- Hadoop установлен в `/opt/hadoop`, каталоги YARN — в `/data/yarn`.
- WebAppProxy работает внутри ResourceManager.

## Запуск

Файлы на edge-ноде находятся в `/home/team/hw2-team07`:

```bash
ssh -i ~/.ssh/имя_ключа team@171.22.73.191
cd /home/team/hw2-team07
bash deploy.sh
```

Параметры подключения — в `config.env`.

## Шаги

### 1. Конфигурация YARN и MapReduce `scripts/1_configure.sh`

### 2. Запуск ResourceManager, NodeManager и JobHistoryServer `scripts/2_start.sh`

### 3. Публикация веб-интерфейсов через Nginx `scripts/3_publish.sh`

## Проверка

```bash
bash scripts/4_check.sh
bash scripts/5_wordcount.sh
```

Результаты на нашем кластере:

- Три NodeManager в состоянии `RUNNING`, нездоровых узлов нет.
- HDFS: три живых DataNode, потерянных и повреждённых блоков нет.
- WordCount: `SUCCEEDED`, один map и один reduce выполнены без ошибок.
- История задачи и агрегированные логи доступны.

Результат WordCount:

```text
hadoop     2
mapreduce  1
yarn       2
```

Журналы проверки — в `evidence/`.

## Веб-интерфейсы

| Интерфейс | Адрес через туннель |
|---|---|
| ResourceManager | http://127.0.0.1:8088/cluster |
| JobHistoryServer | http://127.0.0.1:19888/jobhistory |
| NameNode | http://127.0.0.1:9870/dfshealth.html |
| SecondaryNameNode | http://127.0.0.1:9868/ |
| NodeManager, nn | http://127.0.0.1:18041/node |
| NodeManager, 00 | http://127.0.0.1:18042/node |
| NodeManager, 01 | http://127.0.0.1:18043/node |
| DataNode, nn | http://127.0.0.1:19861/datanode.html |
| DataNode, 00 | http://127.0.0.1:19862/datanode.html |
| DataNode, 01 | http://127.0.0.1:19863/datanode.html |
