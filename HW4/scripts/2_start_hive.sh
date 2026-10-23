#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

site=$HIVE_HOME/conf/hive-site.xml
mkdir -p "$HIVE_LOGS"

stop() {
    pkill -f -- "/java .*-Dproc_$1 " || true
    for _ in $(seq 30); do
        pgrep -f -- "/java .*-Dproc_$1 " >/dev/null || return 0
        sleep 1
    done
    pkill -9 -f -- "/java .*-Dproc_$1 " || true
}

start() {
    nohup "$HIVE_HOME/bin/hive" --service "$1" > "$HIVE_LOGS/$1.log" 2>&1 < /dev/null &
    echo $! > "$HIVE_LOGS/$1.pid"
    for _ in $(seq "$3"); do
        if ss -tln | grep -q ":$2 "; then
            echo "$1 слушает порт $2"
            return 0
        fi
        sleep 2
    done
    tail -n 30 "$HIVE_LOGS/$1.log"
    echo "$1 не открыл порт $2" >&2
    exit 1
}

step "hive-site.xml"
restart=false
[ -f "$site.bak-hw4" ] || cp "$site" "$site.bak-hw4"
for property in hive.metastore.event.db.notification.api.auth hive.server2.enable.doAs; do
    if ! grep -q "<name>$property</name>" "$site"; then
        sed -i "s|</configuration>|  <property>\n    <name>$property</name>\n    <value>false</value>\n  </property>\n</configuration>|" "$site"
        restart=true
    fi
    grep -A1 "<name>$property</name>" "$site" | xargs
done

step "Hive Metastore"
if $restart || ! ss -tln | grep -q ':9083 '; then
    stop metastore
    start metastore 9083 60
else
    echo "metastore уже работает"
fi

step "HiveServer2"
if $restart || ! ss -tln | grep -q ':10000 '; then
    stop hiveserver2
    start hiveserver2 10000 150
else
    echo "hiveserver2 уже работает"
fi
beeline -e "SELECT 'hiveserver2 ok';"
