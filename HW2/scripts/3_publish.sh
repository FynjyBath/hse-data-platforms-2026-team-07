#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
[[ $(hostname -s) == team-07-en ]] || { echo 'Запустите этот шаг на edge-ноде'; exit 1; }
step 'Nginx: резервная копия исходного состояния'
sudo -n install -d -m 700 "$BACKUP_ROOT/initial"
if ! sudo -n test -f "$BACKUP_ROOT/initial/nginx.complete"; then
    if dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -q 'install ok installed'; then
        echo 'present' | sudo -n tee "$BACKUP_ROOT/initial/nginx.package" >/dev/null
    else
        echo 'absent' | sudo -n tee "$BACKUP_ROOT/initial/nginx.package" >/dev/null
    fi
    if sudo -n test -d /etc/nginx; then
        sudo -n tar -C /etc -czf "$BACKUP_ROOT/initial/nginx.tar.gz" nginx
    fi
    systemctl is-active nginx > "$ROOT/.nginx-active" 2>/dev/null || true
    systemctl is-enabled nginx > "$ROOT/.nginx-enabled" 2>/dev/null || true
    sudo -n mv "$ROOT/.nginx-active" "$BACKUP_ROOT/initial/nginx.active"
    sudo -n mv "$ROOT/.nginx-enabled" "$BACKUP_ROOT/initial/nginx.enabled"
    date -Is | sudo -n tee "$BACKUP_ROOT/initial/nginx.complete" >/dev/null
fi
if ! command -v nginx >/dev/null; then
    sudo -n apt-get update -qq
    sudo -n env DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y -qq nginx
fi
step 'Отдельный пароль для просмотра веб-интерфейсов'
install -d -m 700 "$ROOT/.secrets"
if [[ ! -f $ROOT/.secrets/web.htpasswd ]]; then
    umask 077
    password=$(openssl rand -hex 12)
    hash=$(printf '%s\n' "$password" | openssl passwd -6 -stdin)
    printf 'team07:%s\n' "$hash" > "$ROOT/.secrets/web.htpasswd"
    printf 'Login: team07\nPassword: %s\nURL: http://%s:8088/\n' "$password" "$PUBLIC_HOST" > "$ROOT/.secrets/WEB-ACCESS.txt"
    unset password hash
fi
sudo -n install -m 640 -o root -g www-data "$ROOT/.secrets/web.htpasswd" /etc/nginx/team07-hw2.htpasswd
step 'Публикация веб-интерфейсов'
python3 "$ROOT/scripts/render_nginx.py" "$PUBLIC_HOST" > "$ROOT/conf/nginx-team07.conf"
sudo -n install -m 644 "$ROOT/conf/nginx-team07.conf" /etc/nginx/sites-available/team07-hw2
sudo -n ln -sfn /etc/nginx/sites-available/team07-hw2 /etc/nginx/sites-enabled/team07-hw2
sudo -n rm -f /etc/nginx/sites-enabled/default
sudo -n nginx -t
sudo -n systemctl enable nginx
sudo -n systemctl reload-or-restart nginx
echo 'Пароль сохранён в .secrets/WEB-ACCESS.txt; не публикуйте этот файл.'
