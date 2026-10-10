#!/usr/bin/env bash
# Шаг 1. Подготовка узлов.
source "$(dirname "$0")/common.sh"

for node in $NODES; do
    step "$node: подготовка"
    run "$node" <<'EOF'

# Пришлось имя узла сделать чтобы указывало на сетевой IP, а не на 127.0.1.1,
# иначе NameNode слушает только loopback и DataNode с других узлов к ней не подключатся
sed -i '/^127\.0\.1\.1\s/d' /etc/hosts
# cloud-init возвращает эту строку при каждой загрузке — отключаем у него правку /etc/hosts
if [ -f /etc/cloud/cloud.cfg ]; then
    sed -i '/^\s*- update_etc_hosts\s*$/d' /etc/cloud/cloud.cfg
fi
ip=$(getent ahostsv4 "$(hostname)" | awk 'NR == 1 {print $1}')
if [[ -z $ip || $ip == 127.* ]]; then
    echo "Имя $(hostname) не резолвится в сетевой IP, проверьте /etc/hosts" >&2
    exit 1
fi
echo "$(hostname) -> $ip"

if ! command -v java >/dev/null; then
    echo "Установка $JAVA_PACKAGE..."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y -qq -o DPkg::Lock::Timeout=300 "$JAVA_PACKAGE" >/dev/null
fi
java -version 2>&1 | head -1

if ! id "$HADOOP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$HADOOP_USER"
fi
mkdir -p "$DATA_DIR"
chown "$HADOOP_USER:" "$DATA_DIR"
EOF
done

step "$NAMENODE: SSH-ключ пользователя $HADOOP_USER"
pubkey=$(run "$NAMENODE" <<'EOF'
home=$(getent passwd "$HADOOP_USER" | cut -d: -f6)
install -d -m 700 -o "$HADOOP_USER" -g "$HADOOP_USER" "$home/.ssh"
if [ ! -f "$home/.ssh/id_ed25519" ]; then
    sudo -u "$HADOOP_USER" ssh-keygen -q -t ed25519 -N '' -f "$home/.ssh/id_ed25519"
fi
cat "$home/.ssh/id_ed25519.pub"
EOF
)
echo "$pubkey"

for node in $NODES; do
    step "$node: доступ по ключу для $HADOOP_USER@$NAMENODE"
    run "$node" PUBKEY="$pubkey" <<'EOF'
home=$(getent passwd "$HADOOP_USER" | cut -d: -f6)
keys=$home/.ssh/authorized_keys
install -d -m 700 -o "$HADOOP_USER" -g "$HADOOP_USER" "$home/.ssh"
touch "$keys"
if grep -qxF "$PUBKEY" "$keys"; then
    echo "ключ уже добавлен"
else
    echo "$PUBKEY" >> "$keys"
    echo "ключ добавлен"
fi
chown "$HADOOP_USER:" "$keys"
chmod 600 "$keys"
EOF
done

step "$NAMENODE: проверка SSH до всех узлов"
run "$NAMENODE" NODES="$NODES" <<'EOF'
home=$(getent passwd "$HADOOP_USER" | cut -d: -f6)
ssh-keyscan $NODES > "$home/.ssh/known_hosts" 2>/dev/null
chown "$HADOOP_USER:" "$home/.ssh/known_hosts"
for node in $NODES; do
    sudo -u "$HADOOP_USER" ssh -o BatchMode=yes "$node" true
    echo "$HADOOP_USER@$(hostname) -> $node: ok"
done
EOF
