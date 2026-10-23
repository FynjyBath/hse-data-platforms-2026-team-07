#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

step "Spark на YARN: $RAW_DIR -> $DB.$TABLE"
env -u HIVE_HOME "$SPARK_HOME/bin/spark-submit" --conf spark.log.level=WARN "$ROOT/scripts/sales_job.py" \
    "$HDFS_URI$RAW_DIR" "$DB" "$TABLE" "$HDFS_URI$WAREHOUSE_DIR/$DB.db/$TABLE"
