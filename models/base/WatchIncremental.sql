MODEL (
  name tobiko_cloud_tpcdi.watchincremental,
  kind VIEW,
);

select
    *
from tpcdi.tpcdi_100_dbsql_100_stage.v_watchincremental
    
