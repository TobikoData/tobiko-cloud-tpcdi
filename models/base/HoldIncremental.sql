MODEL (
  name tobiko_cloud_tpcdi.holdingincremental,
  kind VIEW,
);

select
    *
from tpcdi.tpcdi_raw_data_100_stage.v_holdingincremental
    

