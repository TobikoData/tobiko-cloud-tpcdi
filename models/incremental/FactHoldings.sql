MODEL (
  name tobiko_cloud_tpcdi.factholdings,
  kind FULL,
  audits (
    NOT_NULL(columns = (currentprice))
)
);


SELECT 
  hh_h_t_id tradeid,
  hh_t_id currenttradeid,
  sk_customerid,
  sk_accountid,
  sk_securityid,
  sk_companyid,
  sk_closedateid sk_dateid,
  sk_closetimeid sk_timeid,
  tradeprice currentprice,
  hh_after_qty currentholding,
  hh.batchid
FROM (
  SELECT 
    *
  FROM tpcdi.tpcdi_100_dbsql_100_stage.v_holdinghistory
  UNION ALL
  SELECT * except(cdc_flag, cdc_dsn)
  FROM tobiko_cloud_tpcdi.holdingincremental) hh
-- Converts to LEFT JOIN if this is run as DQ EDITION. It is possible, because of the issues upstream with DimSecurity/DimAccount on "some" scale factors, that DimTrade may be missing some rows.
--${dq_left_flg}
 LEFT JOIN tobiko_cloud_tpcdi.dimtrade dt
  ON tradeid = hh_t_id