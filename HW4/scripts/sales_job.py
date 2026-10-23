import sys

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

raw_path, database, table, table_path = sys.argv[1:5]

spark = SparkSession.builder.appName("hw4-sales").master("yarn").enableHiveSupport().getOrCreate()
sc = spark.sparkContext
print(f"master={sc.master} application={sc.applicationId} defaultFS={sc._jsc.hadoopConfiguration().get('fs.defaultFS')}")

orders = spark.read.option("header", True).csv(raw_path)
orders.printSchema()

clean = (
    orders.withColumn("order_id", F.col("order_id").cast("long"))
    .withColumn("order_ts", F.to_timestamp("order_ts", "yyyy-MM-dd HH:mm:ss"))
    .withColumn("quantity", F.col("quantity").cast("int"))
    .withColumn("unit_price", F.col("unit_price").cast("double"))
    .dropna(subset=["order_id", "order_ts", "quantity", "unit_price"])
    .withColumn("order_date", F.to_date("order_ts"))
    .withColumn("amount", F.col("quantity") * F.col("unit_price"))
)
print(f"rows: raw={orders.count()} clean={clean.count()}")

daily = (
    clean.groupBy("order_date", "region", "category")
    .agg(
        F.count("*").alias("orders"),
        F.sum("quantity").alias("items"),
        F.round(F.sum("amount"), 2).alias("revenue"),
        F.round(F.avg("amount"), 2).alias("avg_check"),
    )
    .select("region", "category", "orders", "items", "revenue", "avg_check", "order_date")
)

spark.sql(f"CREATE DATABASE IF NOT EXISTS {database}")
(
    daily.write.mode("overwrite")
    .format("parquet")
    .partitionBy("order_date")
    .option("path", table_path)
    .saveAsTable(f"{database}.{table}")
)

spark.sql(f"SHOW PARTITIONS {database}.{table}").show(truncate=False)
spark.table(f"{database}.{table}").orderBy(F.desc("revenue")).show(5)
spark.stop()
