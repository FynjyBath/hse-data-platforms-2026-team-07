#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

step "Чтение $DB.$TABLE через beeline ($HIVE_JDBC)"
beeline -e "
SHOW TABLES IN $DB;
SHOW PARTITIONS $DB.$TABLE;
SELECT * FROM $DB.$TABLE WHERE order_date = '2026-10-01' ORDER BY revenue DESC LIMIT 5;
SELECT order_date, SUM(orders) AS orders, CAST(SUM(revenue) AS DECIMAL(14, 2)) AS revenue FROM $DB.$TABLE GROUP BY order_date ORDER BY order_date;
"
