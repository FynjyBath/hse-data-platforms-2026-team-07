#!/usr/bin/env python3
import ipaddress
import sys

public = str(ipaddress.ip_address(sys.argv[1]))
services = [
    (8088, "team-07-nn", "10.7.0.11", 8088),
    (19888, "team-07-nn", "10.7.0.11", 19888),
    (9870, "team-07-nn", "10.7.0.11", 9870),
    (9868, "team-07-nn", "10.7.0.11", 9868),
    (18041, "team-07-nn", "10.7.0.11", 8042),
    (18042, "team-07-00", "10.7.0.12", 8042),
    (18043, "team-07-01", "10.7.0.13", 8042),
    (19861, "team-07-nn", "10.7.0.11", 9864),
    (19862, "team-07-00", "10.7.0.12", 9864),
    (19863, "team-07-01", "10.7.0.13", 9864),
]
for external, host, ip, internal in services:
    print("server {")
    print(f"    listen {external};")
    if external == 8088:
        print("    listen 80;")
    print(f"    server_name {public};")
    print('    auth_basic "team-07 Hadoop";')
    print("    auth_basic_user_file /etc/nginx/team07-hw2.htpasswd;")
    print("    location / {")
    print("        limit_except GET { deny all; }")
    print(f"        proxy_pass http://{host}:{internal};")
    print("        proxy_set_header Host $http_host;")
    print("        proxy_set_header X-Real-IP $remote_addr;")
    print("        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;")
    print("        proxy_set_header X-Forwarded-Proto $scheme;")
    print('        proxy_set_header Accept-Encoding "";')
    print("        proxy_read_timeout 120s;")
    print("        proxy_redirect default;")
    print("        sub_filter_once off;")
    print("        sub_filter_types application/json text/xml application/xml application/javascript text/javascript;")
    for target_port, target_host, target_ip, target_internal in services:
        for address in (target_host, target_ip):
            original = f"{address}:{target_internal}"
            replacement = f"$host:{target_port}"
            print(f"        proxy_redirect http://{original}/ http://{replacement}/;")
            print(f"        sub_filter '{original}' '{replacement}';")
    print("    }\n}\n")
