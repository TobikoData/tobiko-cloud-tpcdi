MODEL (
  name tobiko_cloud_tpcdi.financial,
  kind FULL,
  audits (
    NOT_NULL(columns = (sk_companyid))
)
);


SELECT 
  sk_companyid,
  fi_year,
  fi_qtr,
  fi_qtr_start_date,
  fi_revenue,
  fi_net_earn,
  fi_basic_eps,
  fi_dilut_eps,
  fi_margin,
  fi_inventory,
  fi_assets,
  fi_liability,
  fi_out_basic,
  fi_out_dilut
FROM (
  SELECT 
    * except(conameorcik),
    nvl(string(try_cast(conameorcik as bigint)), conameorcik) conameorcik
  FROM (
    SELECT
       recdate,
      cast(substring(value, 1, 4) AS INT) AS fi_year,
      cast(substring(value, 5, 1) AS INT) AS fi_qtr,
      to_date(substring(value, 6, 8), 'yyyyMMdd') AS fi_qtr_start_date,
      cast(substring(value, 22, 17) AS DOUBLE) AS fi_revenue,
      cast(substring(value, 39, 17) AS DOUBLE) AS fi_net_earn,
      cast(substring(value, 56, 12) AS DOUBLE) AS fi_basic_eps,
      cast(substring(value, 68, 12) AS DOUBLE) AS fi_dilut_eps,
      cast(substring(value, 80, 12) AS DOUBLE) AS fi_margin,
      cast(substring(value, 92, 17) AS DOUBLE) AS fi_inventory,
      cast(substring(value, 109, 17) AS DOUBLE) AS fi_assets,
      cast(substring(value, 126, 17) AS DOUBLE) AS fi_liability,
      cast(substring(value, 143, 13) AS BIGINT) AS fi_out_basic,
      cast(substring(value, 156, 13) AS BIGINT) AS fi_out_dilut, 
      trim(substring(value, 169, 60)) AS conameorcik
    FROM tobiko_cloud_tpcdi.finwire
    WHERE rectype = 'FIN'
  ) f 
) f
JOIN (
  SELECT 
    sk_companyid,
    name conameorcik,
    EffectiveDate,
    EndDate
  FROM tobiko_cloud_tpcdi.dimcompany
  UNION ALL
  SELECT 
    sk_companyid,
    cast(companyid as string) conameorcik,
    EffectiveDate,
    EndDate
  FROM tobiko_cloud_tpcdi.dimcompany
) dc 
ON
  f.conameorcik = dc.conameorcik 
  AND date(recdate) >= dc.effectivedate 
  AND date(recdate) < dc.enddate