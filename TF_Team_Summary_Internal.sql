--TF Team Summary
-- PS user data from Sandbox and Analytics
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
--TF Course Completions
tfcourse as(
  select 
    userhandle, 
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
        distinct userhandle, 
        case when trim(crtopicname) like 'Data Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as dataflag, 
        case when trim(crtopicname) like 'Cloud Computing Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as cloudflag, 
        case when trim(crtopicname) like 'Security Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as securityflag, 
        case when trim(crtopicname) like 'Automation Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as automationflag, 
        case when trim(crtopicname) like 'Platforms Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as platformflag, 
        case when trim(crtopicname) = 'Artificial Intelligence Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as aiflag, 
        case when trim(crtopicname) = '5G & IOT Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as iotflag, 
        case when trim(crtopicname) = 'API Economy Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as apiflag, 
        case when trim(crtopicname) = 'Agile Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as agileflag, 
        case when trim(crtopicname) = 'Extended Reality & the Metaverse Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as ermetaflag, 
        case when trim(crtopicname) = 'Blockchain Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as blockchainflag, 
        case when trim(crtopicname) = 'Software Development Explained' 
        and passfailskipped like 'Pass' then '1' else '0' end as sdflag 
      from 
        dvs.current_state.skills_criterionref_v2_usercompletionreport
    ) 
  group by 
    1
), 
-- TF count
course as(
  select 
    userhandle, 
    count(distinct crtopicname) as tfcount 
  from 
    dvs.current_state.skills_criterionref_v2_usercompletionreport 
  where 
    passfailskipped like 'Pass' 
  group by 
    1
), 

-- Final Table
fnl as(
  select 
    ps.handle, 
    ps.email, 
    ps.org, 
    ps.team, 
    ps.supervisory_org, 
    coalesce(tfcount,0,'') as tfCount,     
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
    left join course cs on ps.handle = cs.userhandle 
    left join tfcourse tfc on ps.handle = tfc.userhandle
)


select 
DISTINCT email, 
  handle, 
  org, 
  team, 
  supervisory_org, 
  tfcount, 
  Cloud, 
  AI, 
  API, 
  Agile, 
  Platform, 
  Software_Devlopment, 
  Data, 
  IOT, 
  ER_Meta, 
  Blockchain, 
  Automation, 
  Security 
from 
  fnl 
where 
  org not in (
    'Business Ops & Process Design (Thomas Wolf)', 
    'Office of the CEO (Sarah Van Wagoner (On Leave))'
  )