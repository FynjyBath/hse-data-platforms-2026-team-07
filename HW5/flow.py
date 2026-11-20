"""Run the sales ETL on the cluster from HW1–HW4."""

import argparse
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit

from prefect import flow, task
from prefect.task_runners import ThreadPoolTaskRunner


ROOT = Path(__file__).resolve().parent
TABLE = "hw5.sales_by_region"


@task(log_prints=True, cache_policy=None)
def check_input(input_path: str) -> None:
    print(f"Checking the source on HDFS: {input_path}", flush=True)
    subprocess.run(
        [f"{os.environ['HADOOP_HOME']}/bin/hdfs", "dfs", "-test", "-s", input_path],
        check=True,
    )


@task(log_prints=True, cache_policy=None)
def run_spark(input_path: str) -> str:
    spark_env = os.environ.copy()
    spark_env.pop("HIVE_HOME", None)
    command = [
        f"{os.environ['SPARK_HOME']}/bin/spark-submit",
        "--master", "yarn",
        "--deploy-mode", "client",
        "--name", "hw5-prefect-sales",
        "--conf", "spark.log.level=WARN",
        str(ROOT / "sales_etl.py"),
        input_path,
    ]
    application_id = None
    with subprocess.Popen(
        command, env=spark_env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8", errors="replace",
    ) as process:
        assert process.stdout is not None
        for line in process.stdout:
            match = re.search(r"HW5_APPLICATION=(application_\d+_\d+)", line)
            if match:
                application_id = match.group(1)
            print(line, end="", flush=True)
        if process.wait():
            raise subprocess.CalledProcessError(process.returncode, command)
    if application_id is None:
        raise RuntimeError("Spark did not report a YARN application ID")
    return application_id


@task(log_prints=True, cache_policy=None)
def verify_hive(jdbc_url: str) -> None:
    query = (
        f"SELECT COUNT(*) AS groups, SUM(orders) AS orders, "
        f"SUM(revenue) AS revenue FROM {TABLE};"
    )
    result = subprocess.run(
        [
            f"{os.environ['HIVE_HOME']}/bin/beeline",
            "-u", jdbc_url, "--silent=true", "--showHeader=false",
            "--outputformat=tsv2", "-e", query,
        ],
        stdout=subprocess.PIPE, text=True, check=True,
    )
    groups, orders, revenue = result.stdout.strip().split("\t")
    if int(groups) < 1 or int(orders) < 1:
        raise RuntimeError(f"Empty Hive result: {result.stdout!r}")
    print(f"HIVE_OK table={TABLE} groups={groups} orders={orders} revenue={revenue}")


@flow(name="hw5-sales-etl", log_prints=True, task_runner=ThreadPoolTaskRunner(max_workers=1))
def sales_etl(input_path: str, jdbc_url: str) -> None:
    source = urlsplit(input_path)
    if source.scheme != "hdfs" or not source.netloc or not source.path.startswith("/"):
        raise ValueError("Input must be a full hdfs://host:port/path URI")
    check_input(input_path)
    application_id = run_spark(input_path)
    verify_hive(jdbc_url)
    print(f"HW5_OK application={application_id} table={TABLE}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="hdfs://team-07-nn:9000/user/team/hw4/raw/orders.csv")
    parser.add_argument("--jdbc", default="jdbc:hive2://team-07-en:10000/default")
    args = parser.parse_args()
    sales_etl(args.input, args.jdbc)
