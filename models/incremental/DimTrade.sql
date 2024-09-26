MODEL (
  name tobiko_cloud_tpcdi.dimtrade,
  kind FULL,
);

SELECT
  trade.tradeid,
  sk_brokerid,
  trade.sk_createdateid,
  trade.sk_createtimeid,
  trade.sk_closedateid,
  trade.sk_closetimeid,
  st_name status,
  tt_name type,
  trade.cashflag,
  sk_securityid,
  sk_companyid,
  trade.quantity,
  trade.bidprice,
  sk_customerid,
  sk_accountid,
  trade.executedby,
  trade.tradeprice,
  trade.fee,
  trade.commission,
  trade.tax,
  trade.batchid
FROM (
  SELECT * EXCEPT(t_dts)
  FROM (
    SELECT
      tradeid,
      min(date(t_dts)) OVER (PARTITION BY tradeid) createdate,
      t_dts,
      coalesce(sk_createdateid, last_value(sk_createdateid) IGNORE NULLS OVER (
        PARTITION BY tradeid ORDER BY t_dts)) sk_createdateid,
      coalesce(sk_createtimeid, last_value(sk_createtimeid) IGNORE NULLS OVER (
        PARTITION BY tradeid ORDER BY t_dts)) sk_createtimeid,
      coalesce(sk_closedateid, last_value(sk_closedateid) IGNORE NULLS OVER (
        PARTITION BY tradeid ORDER BY t_dts)) sk_closedateid,
      coalesce(sk_closetimeid, last_value(sk_closetimeid) IGNORE NULLS OVER (
        PARTITION BY tradeid ORDER BY t_dts)) sk_closetimeid,
      cashflag,
      t_st_id,
      t_tt_id,
      t_s_symb,
      quantity,
      bidprice,
      t_ca_id,
      executedby,
      tradeprice,
      fee,
      commission,
      tax,
      batchid
    FROM (
      SELECT
        tradeid,
        t_dts,
        if(create_flg, sk_dateid, cast(NULL AS BIGINT)) sk_createdateid,
        if(create_flg, sk_timeid, cast(NULL AS BIGINT)) sk_createtimeid,
        if(!create_flg, sk_dateid, cast(NULL AS BIGINT)) sk_closedateid,
        if(!create_flg, sk_timeid, cast(NULL AS BIGINT)) sk_closetimeid,
        cashflag,
        t_st_id,
        t_tt_id,
        t_s_symb,
        quantity,
        bidprice,
        t_ca_id,
        executedby,
        tradeprice,
        fee,
        commission,
        tax,
        t.batchid
      FROM (
        SELECT
          t_id tradeid,
          th_dts t_dts,
          t_st_id,
          t_tt_id,
          try_cast(t_is_cash as boolean) cashflag,
          t_s_symb,
          quantity,
          bidprice,
          t_ca_id,
          executedby,
          tradeprice,
          fee,
          commission,
          tax,
          1 batchid,
          CASE 
            WHEN (t_st_id == "SBMT" AND t_tt_id IN ("TMB", "TMS")) OR t_st_id = "PNDG" THEN TRUE 
            WHEN t_st_id IN ("CMPT", "CNCL") THEN FALSE 
            ELSE cast(null as boolean) END AS create_flg
        FROM tpcdi.tpcdi_100_dbsql_100_stage.v_trade t
        JOIN tpcdi.tpcdi_100_dbsql_100_stage.v_tradehistory th
          ON th.tradeid = t_id
        UNION ALL
        SELECT
          tradeid,
          t_dts,
          status,
          type,
          cashflag,
          t_s_symb,
           quantity,
          bidprice,
          t_ca_id,
          executedby,
          tradeprice,
          fee,
          commission,
          tax,
          t.batchid,
          CASE 
            WHEN cdc_flag = 'I' THEN TRUE 
            WHEN status IN ("Completed", "Canceled") THEN FALSE 
            ELSE cast(null as boolean) END AS create_flg
        FROM tobiko_cloud_tpcdi.tradeincremental t
      ) t
      JOIN tobiko_cloud_tpcdi.dimdate dd
        ON date(t.t_dts) = dd.datevalue
      JOIN tobiko_cloud_tpcdi.dimtime dt
        ON date_format(t.t_dts, 'HH:mm:ss') = dt.timevalue
    )
  )
  QUALIFY ROW_NUMBER() OVER (PARTITION BY tradeid ORDER BY t_dts desc) = 1
) trade
JOIN tobiko_cloud_tpcdi.statustype status
  ON status.st_id = trade.t_st_id
JOIN tobiko_cloud_tpcdi.tradetype tt
  ON tt.tt_id == trade.t_tt_id
-- Converts to LEFT JOIN if this is run as DQ EDITION. On some higher Scale Factors, a small number of Security symbols or Account IDs are missing from DimSecurity/DimAccount, causing audit check failures. 
--${dq_left_flg} 
LEFT JOIN tobiko_cloud_tpcdi.dimsecurity ds
  ON 
    ds.symbol = trade.t_s_symb
    AND createdate >= ds.effectivedate 
    AND createdate < ds.enddate
--${dq_left_flg} 
LEFT JOIN tobiko_cloud_tpcdi.dimaccount da
  ON 
    trade.t_ca_id = da.accountid 
    AND createdate >= da.effectivedate 
    AND createdate < da.enddate