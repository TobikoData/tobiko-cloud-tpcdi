MODEL (
  name tobiko_cloud_tpcdi.dimcompany,
  kind FULL,
);


SELECT 
  * FROM (
  SELECT
  
    cast(cik as BIGINT) companyid,
    st.st_name status,
    companyname name,
    ind.in_name industry,
    if(
      SPrating IN ('AAA','AA','AA+','AA-','A','A+','A-','BBB','BBB+','BBB-','BB','BB+','BB-','B','B+','B-','CCC','CCC+','CCC-','CC','C','D'), 
      SPrating, 
      cast(null as string)) sprating, 
    CASE
      WHEN SPrating IN ('AAA','AA','A','AA+','A+','AA-','A-','BBB','BBB+','BBB-') THEN false
      WHEN SPrating IN ('BB','B','CCC','CC','C','D','BB+','B+','CCC+','BB-','B-','CCC-') THEN true
      ELSE cast(null as boolean)
      END as islowgrade, 
    ceoname ceo,
    addrline1 addressline1,
    addrline2 addressline2,
    postalcode,
    city,
    stateprovince stateprov,
    country,
    description,
    foundingdate,
    nvl2(lead(recdate) OVER (PARTITION BY cik ORDER BY recdate), true, false) iscurrent,
    1 batchid,
    date(recdate) effectivedate,
    bigint(concat(date_format(effectivedate, 'yyyyMMdd'), cast(companyid as string))) as sk_companyid,
    coalesce(
      lead(date(recdate)) OVER (PARTITION BY cik ORDER BY recdate),
      cast('9999-12-31' as date)) enddate
  FROM (
    SELECT
      recdate,
      trim(substring(value, 1, 60)) AS CompanyName,
      trim(substring(value, 61, 10)) AS CIK,
      trim(substring(value, 71, 4)) AS Status,
      trim(substring(value, 75, 2)) AS IndustryID,
      trim(substring(value, 77, 4)) AS SPrating,
      to_date(try_to_timestamp(substring(value, 81, 8), 'yyyyMMdd')) AS FoundingDate,
      trim(substring(value, 89, 80)) AS AddrLine1,
      trim(substring(value, 169, 80)) AS AddrLine2,
      trim(substring(value, 249, 12)) AS PostalCode,
      trim(substring(value, 261, 25)) AS City,
      trim(substring(value, 286, 20)) AS StateProvince,
      trim(substring(value, 306, 24)) AS Country,
      trim(substring(value, 330, 46)) AS CEOname,
      trim(substring(value, 376, 150)) AS Description
    FROM tobiko_cloud_tpcdi.finwire
    WHERE rectype = 'CMP'
       ) cmp
  JOIN tobiko_cloud_tpcdi.StatusType st ON cmp.status = st.st_id
  JOIN tobiko_cloud_tpcdi.Industry ind ON cmp.industryid = ind.in_id
)
