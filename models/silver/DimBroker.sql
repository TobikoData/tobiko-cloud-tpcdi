MODEL (
  name tobiko_cloud_tpcdi.dimbroker,
  kind FULL,
);



SELECT

  cast(employeeid as BIGINT) brokerid,
  cast(managerid as BIGINT) managerid,
  employeefirstname firstname,
  employeelastname lastname,
  employeemi middleinitial,
  employeebranch branch,
  employeeoffice office,
  employeephone phone,
  true iscurrent,
  1 batchid,
  (SELECT min(to_date(datevalue)) as effectivedate FROM tobiko_cloud_tpcdi.DimDate) effectivedate,
  date('9999-12-31') enddate,
  bigint(concat(date_format(enddate, 'yyyyMMdd'), cast(brokerid as string))) as sk_brokerid
FROM  tpcdi.tpcdi_100_dbsql_100_stage.v_hr
WHERE employeejobcode = 314