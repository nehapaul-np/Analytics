-- TF Internal PS user data workday
with ps_users as (
 SELECT
	worker AS NAME,
	exec_org_new AS org,
	cost_center AS team,
	supervisory_org,
	employee_email AS email,
	id.HANDLE
FROM
	analytics.sandbox.ne_ps_users_teams ps
LEFT JOIN GOLD.INTEGRATION."USER" id ON
	id.email = ps.employee_email
), 

--tfcount
total_tf_count AS (
SELECT
	DISTINCT USERID,
	COUNT(DISTINCT SUBJECTID)  AS tf_count
FROM
	DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V9_CRITERIONREFERENCEDASSESSMENTS
WHERE
	PASSFAILSKIPPED = 'Pass' 
	GROUP BY 1	
),

-- TF Course Completion 
tfcourse as(
  select 
    USERID, 
    max (dataflag) as Data, 
    max (cloudflag) as Cloud, 
    max (securityflag) as Security, 
    max (automationflag) as Automation, 
    max (platformflag) as Platform, 
    max (aiflag) as AI, 
    max (iotflag) as IOT, 
    max (apiflag) as API, 
    max (agileflag) as Agile, 
    max (ermetaflag) as ER_Meta, 
    max (blockchainflag) as Blockchain, 
    max (sdflag) as Software_Devlopment 
  from 
    (
      select 
        distinct userid, 
        case when trim(SUBJECTNAME) like 'Data' 
        and passfailskipped like 'Pass' then '1' else '0' end as dataflag, 
        case when trim(SUBJECTNAME) like 'Cloud Computing' 
        and passfailskipped like 'Pass' then '1' else '0' end as cloudflag, 
        case when trim(SUBJECTNAME) like 'Security' 
        and passfailskipped like 'Pass' then '1' else '0' end as securityflag, 
        case when trim(SUBJECTNAME) like 'Automation' 
        and passfailskipped like 'Pass' then '1' else '0' end as automationflag, 
        case when trim(SUBJECTNAME) like 'Platforms' 
        and passfailskipped like 'Pass' then '1' else '0' end as platformflag, 
        case when trim(SUBJECTNAME) = 'Artificial Intelligence' 
        and passfailskipped like 'Pass' then '1' else '0' end as aiflag, 
        case when trim(SUBJECTNAME) = '5G & IOT' 
        and passfailskipped like 'Pass' then '1' else '0' end as iotflag, 
        case when trim(SUBJECTNAME) = 'API Economy' 
        and passfailskipped like 'Pass' then '1' else '0' end as apiflag, 
        case when trim(SUBJECTNAME) = 'Agile' 
        and passfailskipped like 'Pass' then '1' else '0' end as agileflag, 
        case when trim(SUBJECTNAME) = 'Extended Reality & the Metaverse' 
        and passfailskipped like 'Pass' then '1' else '0' end as ermetaflag, 
        case when trim(SUBJECTNAME) = 'Blockchain' 
        and passfailskipped like 'Pass' then '1' else '0' end as blockchainflag, 
        case when trim(SUBJECTNAME) = 'Software Development' 
        and passfailskipped like 'Pass' then '1' else '0' end as sdflag 
      from 
        DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V9_CRITERIONREFERENCEDASSESSMENTS
    ) 
  group by 
    1
), 

-- Final Table
fnl as(
  select 
    ps.handle, 
    ps.email, 
    ps.name, 
    ps.org, 
    ps.team, 
    ps.supervisory_org, 
    COALESCE(tcount.tf_count, 0) AS tf_count,
    coalesce(Data,0,'') as Data, 
    coalesce(Cloud,0,'') as Cloud, 
    coalesce(Security,0,'') as Security, 
    coalesce(Automation,0,'') as Automation, 
    coalesce(Platform,0,'') as Platform, 
    coalesce(AI,0,'') as AI, 
    coalesce(IOT,0,'') as IOT, 
    coalesce(API,0,'') as API, 
    coalesce(Agile,0,'') as Agile, 
    coalesce(ER_Meta,0,'') as ER_Meta, 
    coalesce(Blockchain,0,'') as Blockchain, 
    coalesce(Software_Devlopment,0,'') as Software_Devlopment
  from 
    ps_users ps 
    left join tfcourse tfc on ps.handle = tfc.userid
    LEFT JOIN total_tf_count tcount
	ON
	ps.handle = tcount.userid
)

SELECT DISTINCT ps.* FROM fnl ps


--updated sql as we are depending on new model
with ps_users as (

SELECT DISTINCT
	PREFERRED_NAME AS NAME,
	-- exec_org_new AS org,
	 COST_CENTER AS team,
	-- supervisory_org,
	PRIMARY_WORK_EMAIL AS email,
    id.HANDLE
FROM
	people_analytics.nonsensitive.workday_current_roster_nonsensitive ps
LEFT JOIN GOLD.INTEGRATION."USER" id ON
	id.email = ps.PRIMARY_WORK_EMAIL
WHERE
	ps.EMPLOYEE_TYPE LIKE 'Regular' AND ps.TERM_FLAG = 0

),

--tfcount
total_tf_count AS (
SELECT
	DISTINCT USERID,
	COUNT(DISTINCT SUBJECTID)  AS tf_count
FROM
	DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V9_CRITERIONREFERENCEDASSESSMENTS
WHERE
	PASSFAILSKIPPED = 'Pass' 
	GROUP BY 1	
),

-- TF Course Completion 
tfcourse as(
  select 
    USERID, 
    max (dataflag) as Data, 
    max (cloudflag) as Cloud, 
    max (securityflag) as Security, 
    max (automationflag) as Automation, 
    max (platformflag) as Platform, 
    max (aiflag) as AI, 
    max (iotflag) as IOT, 
    max (apiflag) as API, 
    max (agileflag) as Agile, 
    max (ermetaflag) as ER_Meta, 
    max (blockchainflag) as Blockchain, 
    max (sdflag) as Software_Devlopment 
  from 
    (
      select 
        distinct userid, 
        case when trim(SUBJECTNAME) like 'Data' 
        and passfailskipped like 'Pass' then '1' else '0' end as dataflag, 
        case when trim(SUBJECTNAME) like 'Cloud Computing' 
        and passfailskipped like 'Pass' then '1' else '0' end as cloudflag, 
        case when trim(SUBJECTNAME) like 'Security' 
        and passfailskipped like 'Pass' then '1' else '0' end as securityflag, 
        case when trim(SUBJECTNAME) like 'Automation' 
        and passfailskipped like 'Pass' then '1' else '0' end as automationflag, 
        case when trim(SUBJECTNAME) like 'Platforms' 
        and passfailskipped like 'Pass' then '1' else '0' end as platformflag, 
        case when trim(SUBJECTNAME) = 'Artificial Intelligence' 
        and passfailskipped like 'Pass' then '1' else '0' end as aiflag, 
        case when trim(SUBJECTNAME) = '5G & IOT' 
        and passfailskipped like 'Pass' then '1' else '0' end as iotflag, 
        case when trim(SUBJECTNAME) = 'API Economy' 
        and passfailskipped like 'Pass' then '1' else '0' end as apiflag, 
        case when trim(SUBJECTNAME) = 'Agile' 
        and passfailskipped like 'Pass' then '1' else '0' end as agileflag, 
        case when trim(SUBJECTNAME) = 'Extended Reality & the Metaverse' 
        and passfailskipped like 'Pass' then '1' else '0' end as ermetaflag, 
        case when trim(SUBJECTNAME) = 'Blockchain' 
        and passfailskipped like 'Pass' then '1' else '0' end as blockchainflag, 
        case when trim(SUBJECTNAME) = 'Software Development' 
        and passfailskipped like 'Pass' then '1' else '0' end as sdflag 
      from 
        DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V9_CRITERIONREFERENCEDASSESSMENTS
    ) 
  group by 
    1
), 

-- Final Table
fnl as(
  select 
    ps.handle, 
    ps.email, 
    ps.name, 
    --ps.org, 
    ps.team, 
    --ps.supervisory_org, 
    COALESCE(tcount.tf_count, 0) AS tf_count,
    coalesce(Data,0,'') as Data, 
    coalesce(Cloud,0,'') as Cloud, 
    coalesce(Security,0,'') as Security, 
    coalesce(Automation,0,'') as Automation, 
    coalesce(Platform,0,'') as Platform, 
    coalesce(AI,0,'') as AI, 
    coalesce(IOT,0,'') as IOT, 
    coalesce(API,0,'') as API, 
    coalesce(Agile,0,'') as Agile, 
    coalesce(ER_Meta,0,'') as ER_Meta, 
    coalesce(Blockchain,0,'') as Blockchain, 
    coalesce(Software_Devlopment,0,'') as Software_Devlopment
  from 
    ps_users ps 
    left join tfcourse tfc on ps.handle = tfc.userid
    LEFT JOIN total_tf_count tcount
	ON
	ps.handle = tcount.userid
)

SELECT DISTINCT ps.* FROM fnl ps