"""Clean order data and publish daily region totals through Hive Metastore."""

import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


TABLE = "hw5.sales_by_region"
COLUMNS = ("order_id", "order_ts", "region", "quantity", "unit_price")


def transform(orders):
    return (
        orders.select(
            F.expr("try_cast(order_id as bigint)").alias("order_id"),
            F.to_date(F.expr("try_to_timestamp(order_ts, 'yyyy-MM-dd HH:mm:ss')"))
            .alias("order_date"),
            F.trim("region").alias("region"),
            F.expr("try_cast(quantity as int)").alias("quantity"),
            F.expr("try_cast(unit_price as decimal(12,2))").alias("unit_price"),
        )
        .dropna()
        .where("region <> '' AND order_id > 0 AND quantity > 0 AND unit_price >= 0")
        .withColumn("amount", F.col("quantity") * F.col("unit_price"))
    )


def run(input_path: str) -> None:
    spark = SparkSession.builder.enableHiveSupport().getOrCreate()
    try:
        sc = spark.sparkContext
        if sc.master != "yarn" or not sc.applicationId.startswith("application_"):
            raise RuntimeError(f"Expected a YARN application, got {sc.master}/{sc.applicationId}")
        print(f"HW5_APPLICATION={sc.applicationId}", flush=True)
        print(f"master={sc.master} input={input_path}", flush=True)

        orders = spark.read.option("header", True).option("mode", "FAILFAST").csv(input_path)
        missing = set(COLUMNS).difference(orders.columns)
        if missing:
            raise ValueError(f"Missing input columns: {', '.join(sorted(missing))}")
        clean = transform(orders).cache()
        raw_count = orders.count()
        clean_count = clean.count()
        if not clean_count:
            raise ValueError("No valid orders to publish")

        daily = clean.groupBy("order_date", "region").agg(
            F.count("*").alias("orders"),
            F.sum("quantity").alias("items"),
            F.sum("amount").cast("decimal(24,2)").alias("revenue"),
            F.avg("amount").cast("decimal(24,2)").alias("avg_order_value"),
        )
        spark.sql("CREATE DATABASE IF NOT EXISTS hw5")
        spark.sql(f"""
            CREATE TABLE IF NOT EXISTS {TABLE} (
                order_date DATE, region STRING, orders BIGINT,
                items BIGINT, revenue DECIMAL(24,2), avg_order_value DECIMAL(24,2)
            ) STORED AS PARQUET
        """)
        daily.createOrReplaceTempView("hw5_daily_result")
        spark.sql(f"INSERT OVERWRITE TABLE {TABLE} SELECT * FROM hw5_daily_result")

        stored = spark.table(TABLE)
        totals = stored.agg(F.count("*"), F.sum("orders")).first()
        if totals[1] != clean_count:
            raise RuntimeError(f"Expected {clean_count} valid orders, read back {totals[1]}")
        print(
            f"SPARK_OK raw={raw_count} valid={clean_count} rejected={raw_count - clean_count} "
            f"groups={totals[0]} table={TABLE}",
            flush=True,
        )
        stored.orderBy("order_date", "region").show(5, truncate=False)
    finally:
        spark.stop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_path")
    run(parser.parse_args().input_path)
