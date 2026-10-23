#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

step "Генерация $ROWS заказов"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 - "$ROWS" > "$tmp/orders.csv" <<'PY'
import csv
import random
import sys
from datetime import datetime, timedelta

random.seed(7)
regions = ["Moscow", "Saint Petersburg", "Kazan", "Novosibirsk", "Yekaterinburg"]
prices = {"electronics": (50, 900), "books": (5, 40), "clothes": (15, 150), "food": (2, 30), "toys": (8, 80)}
start = datetime(2026, 10, 1)
out = csv.writer(sys.stdout)
out.writerow(["order_id", "order_ts", "region", "category", "quantity", "unit_price"])
for order_id in range(1, int(sys.argv[1]) + 1):
    category = random.choice(list(prices))
    ts = start + timedelta(seconds=random.randrange(7 * 86400))
    quantity = random.randint(1, 5) if random.random() > 0.01 else "n/a"
    price = f"{random.uniform(*prices[category]):.2f}"
    out.writerow([order_id, ts.strftime("%Y-%m-%d %H:%M:%S"), random.choice(regions), category, quantity, price])
PY
head -n 4 "$tmp/orders.csv"

step "Загрузка в HDFS: $RAW_DIR"
hdfs dfs -mkdir -p "$RAW_DIR"
hdfs dfs -put -f "$tmp/orders.csv" "$RAW_DIR/orders.csv"
hdfs dfs -ls "$RAW_DIR"
