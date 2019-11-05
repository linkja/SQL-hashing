USE $(Database)
GO

/*to standardize data, generate composite patient identifiers and hash them*/
/*to run SQL scripts directly, map these to real database, objects, tables & field names:
$(Database),$(schema),$(hashTable),$(temptablename),$(sourceTable),
$(patientid),$(name1),$(name2),$(dob),$(ssn),$(exclusion) and
replace these with real values:
'$(siteid)','$(privateSalt)','$(projectSalt)','$(projectid)','$(privateDate)'*/

DECLARE @siteid VARCHAR(20)
--DECLARE @Sitename VARCHAR(20)
DECLARE @projectid VARCHAR(20)
DECLARE @privatesalt VARCHAR(20)
DECLARE @privatedate date
DECLARE @projectsalt VARCHAR(20)

SET @siteid= '$(siteid)' --'3'
--SET @Sitename= --'COOKCOUNTY'
SET @privatesalt= '$(privateSalt)' --'uu0jupHjaDGeP'
SET @projectsalt= '$(projectSalt)' --'vPCtDqKNJ0fcC'
SET @projectid= '$(projectid)' --'project1'
SET @privatedate= '$(privateDate)' --'01-01-2018'

IF OBJECT_ID(N'$(hashTable)', N'U') IS NOT NULL
BEGIN
  DROP TABLE $(hashTable)
END;

IF OBJECT_ID(N'tempdb..$(temptablename)', N'U') IS NOT NULL
BEGIN
  DROP TABLE $(temptablename)
END;

SELECT CONCAT(COUNT(*), ' records read')
FROM $(sourceTable)

/*remove suffix, prefix, replace multiple spaces & hypens with single space*/
;with cteclean AS (
SELECT siteid = @siteid
      ,projectid = @projectid
      ,$(patientid) internalid
      ,$(schema).fnRemoveSuffix2($(schema).fnRemovePrefix2($(name1))) name1_0
      ,$(schema).fnRemoveSuffix2($(schema).fnRemovePrefix2($(name2))) name2_0
	  ,CASE WHEN ltrim(rtrim(REPLACE($(dob), char(9), ''))) IN ('') THEN NULL ELSE CAST($(dob) AS DATE) END dob 
	  ,CASE WHEN $(ssn) IN ('0') THEN NULL ELSE $(schema).fnNumberOnly($(ssn)) END ssn
	  ,$(exclusion) exclusion
FROM $(sourceTable)
),

/*split 2 last names and generate derived last name rows with original data and flag the new rows with space hyphen derivative flag*/
cteunion AS (
SELECT DISTINCT siteid,projectid,internalid,$(schema).fnAlphaOnly(name1_0) name1,$(schema).fnAlphaOnly(name2) name2,
                dob,ssn,exclusion,
				CASE WHEN names IN ('name2_1','name2_2') THEN 1 ELSE 0 END shy_der_flag
FROM
(
	SELECT siteid
		  ,projectid
		  ,internalid
		  ,name1_0
		  ,name2_0
		  ,CASE WHEN PATINDEX('% %',name2_0)>0  THEN RIGHT(name2_0, PATINDEX('% %',reverse(name2_0))-1)
				ELSE NULL
		   END name2_1
		  ,CASE WHEN PATINDEX('% %',name2_0)>0  THEN LEFT(name2_0, PATINDEX('% %',(name2_0))-1)
				ELSE NULL
		   END name2_2
		  ,dob
		  ,CASE WHEN ssn IN ('','0000') OR LEN(ssn)<>4 THEN NULL ELSE ssn END ssn
		  ,exclusion
	FROM cteclean
/*	WHERE 
	  name1_0 NOT LIKE '% BOY %' AND 
	  name1_0 NOT LIKE '% GIRL %' AND 
	  name1_0 NOT LIKE '% BABY %' AND 
	  name1_0 NOT LIKE '% TWIN %' AND
      name1_0 NOT LIKE '% BOY' AND 
	  name1_0 NOT LIKE '% GIRL' AND
	  name1_0 NOT LIKE '% BABY' AND 
	  name1_0 NOT LIKE '% TWIN' AND 
	  name1_0 NOT LIKE 'BOY %' AND
	  name1_0 NOT LIKE 'GIRL %' AND 
	  name1_0 NOT LIKE 'BABY %' AND
	  name1_0 NOT LIKE 'TWIN %' AND
	  name2_0 NOT LIKE '% BOY %' AND 
	  name2_0 NOT LIKE '% GIRL %' AND 
	  name2_0 NOT LIKE '% BABY %' AND 
	  name2_0 NOT LIKE '% TWIN %' AND
      name2_0 NOT LIKE '% BOY' AND 
	  name2_0 NOT LIKE '% GIRL' AND
	  name2_0 NOT LIKE '% BABY' AND 
	  name2_0 NOT LIKE '% TWIN' AND 
	  name2_0 NOT LIKE 'BOY %' AND
	  name2_0 NOT LIKE 'GIRL %' AND 
	  name2_0 NOT LIKE 'BABY %' AND
	  name2_0 NOT LIKE 'TWIN %'
*/
) AS cp
UNPIVOT 
(
  name2 FOR names IN (name2_0,name2_1,name2_2)
) AS up
)

/*select valid data*/
SELECT * INTO $(temptablename)
FROM cteunion
WHERE 
/*name1 NOT IN 
      ('UNKNOWN','MALE','FEMALE','BABY','BOY','GIRL','TWINA','TWINB','TWIN','JOHNDOE','JANEDOE',
	   'UNK','TRA','UNKTRA','UNKTRAUMA','UNKNOWNTRAUMA','TRAUMA','PMCERT','UNTRA','PMCERT','') AND
*/name1 IS NOT NULL AND LEN(name1)>1 AND
/* name2 NOT IN 
	  ('UNKNOWN','MALE','FEMALE','BABY','BOY','GIRL','TWINA','TWINB','TWIN','JOHNDOE','JANEDOE',
	   'UNK','TRA','UNKTRA','UNKTRAUMA','UNKNOWNTRAUMA','TRAUMA','PMCERT','UNTRA','PMCERT','') AND
*/name2 IS NOT NULL AND LEN(name2)>1 AND 
  dob IS NOT NULL  

/*create indexes to improve performance*/
CREATE NONCLUSTERED INDEX ix_0 ON $(temptablename) (internalid);
CREATE NONCLUSTERED INDEX ix_1 ON $(temptablename) (name1);
--CREATE NONCLUSTERED INDEX ix_2 ON $(temptablename) (name2);
CREATE NONCLUSTERED INDEX ix_3 ON $(temptablename) (dob);
CREATE NONCLUSTERED INDEX ix_4 ON $(temptablename) (ssn);
--CREATE NONCLUSTERED INDEX cx_123 ON $(temptablename) (name1,name2,dob);
--CREATE NONCLUSTERED INDEX cx_213 ON $(temptablename) (name2,name1,dob);
--CREATE NONCLUSTERED INDEX cx_1234 ON $(temptablename) (name1,name2,dob,ssn);
--CREATE NONCLUSTERED INDEX cx_2134 ON $(temptablename) (name2,name1,dob,ssn);
	  
/*for logging, count the patient IDs that met the valid data criteria*/
SELECT CONCAT(COUNT(DISTINCT internalid), ' records met criteria')
FROM $(temptablename)

/*create composite identifiers and hash them*/
SELECT * INTO $(hashTable) FROM (
SELECT 
siteid
,projectid
,internalid
--,PIDHASH = $(schema).fnHashBytes2(CONCAT(internalid,siteid),@privatesalt)
,PIDHASH = $(schema).fnHashBytes2(CONCAT(internalid,siteid,datediff(dd,dob,@privatedate)),@privatesalt)
,hash1 = CASE WHEN ssn IS NULL THEN CONVERT(VARCHAR(128), NULL)
                         ELSE $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,dob,ssn) as varchar(max)),@projectsalt) 
					END --fnamelnamedobssn
,hash2 = CASE WHEN ssn IS NULL THEN CONVERT(VARCHAR(128), NULL)
                         ELSE $(schema).fnHashBytes2(CAST(CONCAT(name2,name1,dob,ssn) as varchar(max)),@projectsalt) 
					END --lnamefnamedobssn
,hash3 = $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,dob) as varchar(max)),@projectsalt) --fnamelnamedob
,hash4 = $(schema).fnHashBytes2(CAST(CONCAT(name2,name1,dob) as varchar(max)),@projectsalt) --lnamefnamedob
,hash5 = CASE WHEN ssn IS NULL THEN CONVERT(VARCHAR(128), NULL)
                          ELSE $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,$(schema).fnFormatDate(dob,'YYYY-DD-MM'),ssn) as varchar(max)),@projectsalt)
                     END --fnamelnameTdobssn
,hash6 = $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,$(schema).fnFormatDate(dob,'YYYY-DD-MM')) as varchar(max)),@projectsalt) --fnamelnameTdob
,hash7 = CASE WHEN ssn IS NULL OR shy_der_flag=1 THEN CONVERT(VARCHAR(128), NULL)
                          ELSE $(schema).fnHashBytes2(CAST(CONCAT(substring(name1,1,3),name2,dob,ssn) as varchar(max)),@projectsalt)
					 END --fname3lnamedobssn
,hash8 = CASE WHEN shy_der_flag=1 THEN CONVERT(VARCHAR(128), NULL)
                       ELSE $(schema).fnHashBytes2(CAST(CONCAT(substring(name1,1,3),name2,dob) as varchar(max)),@projectsalt)   
                  END --fname3lnamedob
,hash9 = CASE WHEN ssn IS NULL THEN CONVERT(VARCHAR(128), NULL)
                          ELSE $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,dateadd(dd,1,dob),ssn) as varchar(max)),@projectsalt)
					 END --fnamelnamedobDssn
,hash10 = CASE WHEN ssn IS NULL THEN CONVERT(VARCHAR(128), NULL)
                          ELSE $(schema).fnHashBytes2(CAST(CONCAT(name1,name2,dateadd(YYYY,1,dob),ssn) as varchar(max)),@projectsalt)
					 END --fnamelnamedobYssn
,exclusion
FROM $(temptablename)
) t1
