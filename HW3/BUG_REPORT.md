HiveServer2 не открывал порт 10000: главный поток бесконечно ждал в `HiveServer2.startHiveServer2`, потому что каждая попытка запуска завершалась ошибкой и сервер уходил на повтор через 60 секунд. Настоящая причина нашлась в `/tmp/$USER/hive.log`, а не в `hiveserver2.log`:

1. `Not authorized to make the get_notification_events_count call` — Metastore отклонял `get_current_notificationEventId` от пользователя `team`. Решение: `hive.metastore.event.db.notification.api.auth=false`.
2. После этого при подключении появлялась ошибка `User: team is not allowed to impersonate team`. Решение: `hive.server2.enable.doAs=false`, чтобы запросы выполнялись от пользователя, под которым работает HiveServer2.
3. `Permission denied: user=team, access=WRITE, inode="/tmp"` — в HDFS не было `/tmp/hive`. Каталоги теперь создаются в `scripts/5_start_services.sh`.

Кроме того, `hive.execution.engine=mr` нужен, потому что Tez не установлен, а переменные из `config.env` теперь экспортируются, чтобы `envsubst` подставлял их в `hive-site.xml`.
