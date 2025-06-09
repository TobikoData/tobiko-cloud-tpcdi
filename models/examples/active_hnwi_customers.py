import typing as t
from datetime import datetime

from pyspark.sql import DataFrame, functions as F
from sqlmesh import ExecutionContext, model

@model(
    "tobiko_cloud_tpcdi.dim_active_hnwi_customers",
    columns={
        "customerid": "int",
        "fullname": "text",
        "status": "text",
        "networth": "double",
        "is_hnwi": "boolean",
    },
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> DataFrame:
    # Resolve and read the upstream DimCustomer table
    table = context.resolve_table("tobiko_cloud_tpcdi.dimcustomer")
    df = context.spark.table(table)

    # Transform
    result = (
        df.filter(F.col("status") == "Active")
          .withColumn("is_hnwi", F.col("networth") > 1_000_000)
          .select(
              F.col("customerid"),
              F.concat_ws(" ", F.col("firstname"), F.col("lastname")).alias("fullname"),
              "status",
              "networth",
              "is_hnwi"
          )
    )

    return result
