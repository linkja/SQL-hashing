--while running sql script, please replace below values with real values:
----$(hashTable),$(sourceTable),$(schema)(schema used when creating functions e.g. dbo)

;with cte as (
select enterpriseid,last,first,dob,ssn, 
--shows data values prior to data transformations 
--(i.e., prior to removing special characters, suffix, prefix etc.)
case when p.last=''  then 'last name-missing'
     
	 when len(p.last)=1 then 'last name-1 letter'
     
	 when p.last in ('UNKNOWN','MALE','FEMALE','BABY','BOY','GIRL','TWINA','TWINB','TWIN','JOHNDOE','JANEDOE','TEST',
	   'UNK','TRA','UNKTRA','UNKTRAUMA','UNKNOWNTRAUMA','TRAUMA','PMCERT','UNTRA','PMCERT','STUDENTHEALTH',
	   'STUDY','RESEARCH','FOXNEWS','SECURITIES','CORPORATE','EXPOSURE','DOWNTIME','EOHS') then 'last name-default value' 
     
	 when p.first='' then 'first name-missing'

	 when len(p.first)=1 then 'first name-1 letter'
	 
	 when p.first in ('UNKNOWN','MALE','FEMALE','BABY','BOY','GIRL','TWINA','TWINB','TWIN','JOHNDOE','JANEDOE','TEST',
	   'UNK','TRA','UNKTRA','UNKTRAUMA','UNKNOWNTRAUMA','TRAUMA','PMCERT','UNTRA','PMCERT','STUDENTHEALTH',
	   'STUDY','RESEARCH','FOXNEWS','SECURITIES','CORPORATE','EXPOSURE','DOWNTIME','EOHS') then 'first name-default value'
	 
	 when p.first LIKE '% BOY %' OR p.first LIKE '% GIRL %' OR p.first LIKE '% BABY %' OR p.first  LIKE '% TWIN %' OR p.first  LIKE '% BOY' OR 
		  p.first LIKE '% GIRL' OR p.first  LIKE '% BABY' OR p.first  LIKE '% TWIN' OR p.first  LIKE 'BOY %' OR p.first  LIKE 'GIRL %' OR 
		  p.first LIKE 'BABY %' OR p.first  LIKE 'TWIN %' OR p.last  LIKE '% BOY %' OR p.last  LIKE '% GIRL %' OR p.last  LIKE '% BABY %' OR 
		  p.last  LIKE '% TWIN %' OR p.last  LIKE '% BOY' OR p.last  LIKE '% GIRL' OR p.last  LIKE '% BABY' OR p.last  LIKE '% TWIN' OR 
          p.last  LIKE 'BOY %' OR p.last  LIKE 'GIRL %' OR p.last  LIKE 'BABY %' OR p.last  LIKE 'TWIN %' then 'baby-default value'
	 
	 when concat(first,last) IN ('JOHNDOE','JONDOE','JANEDOE') then 'combined names-default value'
	
	 when len($(schema).fnRemoveSuffix2($(schema).fnRemovePrefix2([FIRST])))=1 or
	      len($(schema).fnRemoveSuffix2($(schema).fnRemovePrefix2(LAST)))=1 then 'name-post cleaning 1 letter '

     when p.dob=''  then 'dob-missing' 
	 
	 when p.dob='1/1/1900' then 'dob-1/1/1900'

     when DATEDIFF(YEAR,p.dob,GETDATE()) not between 0 AND 122 then 'dob-not between 0 and 122'

else 'UNKNOWN' END reason_invalid_data

from $(sourceTable) p  left outer join $(hashTable) h on p.[EnterpriseID]=h.internalid
where h.internalid is null
)

select reason_invalid_data, count(*) count_invalid_data
from cte
group by reason_invalid_data
order by reason_invalid_data