MODEL (
  name tobiko_cloud_tpcdi.customermgmtview,
  kind VIEW,
);

select
    *
from tpcdi.tpcdi_raw_data_100_stage.customermgmt
    
