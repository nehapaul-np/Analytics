--version1
--Add the User plan level details Next!

WITH cte1 AS (
SELECT
	a.create_date,
	a.ASSESSMENT_UUID,
	a.ASSESSMENT_NAME,
	a.skillassessmentsessionid,
	a.userhandle,
	a.id,
	a.contentid,
	a.contenttype,
	a.courseid,
	b.MODULE_TITLE,
	b.CLIP_ID,
	b.CLIP_TITLE
FROM
	analytics.sandbox.ne_skilliq_recommended_module a
LEFT JOIN ANALYTICS.SANDBOX.NE_COURSE_METADATA b ON
	a.contentid = b.MODULE_ID
),

cte2 AS (
SELECT
	USERID AS Userhandle,
	USEREMAIL,
	STARTUTC,
	CLIPID,
	AUTHORNAME,
	CLIPLENGTHINSECONDS,
	VIEWTIMEINSECONDS,
	MODULEID,
	COURSEID,
	COURSETITLE,
	PLANNAME
FROM
	SOURCE_SYSTEM.MSSQL.CLIPVIEW_FULL
),

cte3 AS (
SELECT
	a.CREATE_DATE,
	a.ASSESSMENT_UUID,
	a.ASSESSMENT_NAME,
	a.SKILLASSESSMENTSESSIONID,
	a.USERHANDLE,
	a.CONTENTID AS module_id,
	a.CONTENTTYPE,
	a.COURSEID,
	a.Module_title,
	a.Clip_id,
	a.Clip_title,
	b.USEREMAIL,
	b.PLANNAME,
	b.COURSETITLE,
	MAX(b.CLIPLENGTHINSECONDS) AS Clip_Length,
	SUM(b.VIEWTIMEINSECONDS) AS viewtimeinsec,
	CASE
		WHEN SUM(b.VIEWTIMEINSECONDS) = 0 THEN 'Not Started'
		WHEN SUM(b.VIEWTIMEINSECONDS) >= MAX(b.CLIPLENGTHINSECONDS) THEN 'Module Complete'
		WHEN SUM(b.VIEWTIMEINSECONDS) <= MAX(b.CLIPLENGTHINSECONDS) THEN 'In Progress'
		ELSE NULL
	END AS Module_Status
FROM
	cte1 a
LEFT JOIN cte2 b ON
	a.Clip_id = b.CLIPID
WHERE
	b.STARTUTC >= a.CREATE_DATE
GROUP BY
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14
)

SELECT
	DISTINCT *
FROM
	cte3


*****************************************************************************************
--version 2
--Model is still in my local dbt, will migrate to org dbt soon. Now model took just 12 min for last 12 months data.
--List of Gap Recommended modules (Model_Name : NE_SKILLIQ_RECOMMENDED_MODULE)
WITH gap_module AS (
SELECT
	tim.SKILLASSESSMENTSESSIONID,
	tim.USERHANDLE,
	f2.value:contentId::STRING AS contentId,
	f2.value:contentType::STRING AS contentType,
	f2.value:courseId::STRING AS courseID
FROM
	dvs.current_state.SKILLS_SKILLIQ_V1_CONTENTRECOMMENDATIONS tim,
	LATERAL FLATTEN(INPUT => tim.GAPS) f,
	LATERAL FLATTEN(INPUT => f.value) f1,
	LATERAL FLATTEN(INPUT => f1.value) f2
),

gap_module_details AS(
SELECT
	DISTINCT
	a.SKILLASSESSMENTSESSIONID,
	a.USERHANDLE,
	a.contentId,
	a.contentType,
	a.courseID,
	b.ASSESSMENT_UUID,
	b.ASSESSMENT_NAME,
	c.PLANID,
	d.email
FROM
	gap_module a
LEFT JOIN
    ANALYTICS.CERTIFIED.PX_USER_SKILL_ASSESSMENT_SESSION_EXPANDED b
ON
	b.ASSESSMENT_SESSION_ID = a.SKILLASSESSMENTSESSIONID
LEFT JOIN 
    ANALYTICS.CERTIFIED.PX_ACTIVE_USERS_V2021 c
ON
	a.userhandle = c.USERHANDLE
LEFT JOIN DVS.current_state.EXP_IDENTITY_USER D
ON
	a.userhandle = d.handle
)

SELECT
	a.ASSESSMENTID,
	a.USERHANDLE,
	date(to_timestamp(a.COMPLETEDON,
	3)) AS Assessment_completed_date,
	date(to_timestamp(a.STARTEDON,
	3)) AS Assessment_start_date,
	a.ISHIGHERSCORE,
	a.ID AS Assessment_session_id,
	a.SCORE,
	a.ISRETAKE,
	a.PERCENTILE,
	a.QUINTILELEVEL,
	b.USERHANDLE as handle,
	b.contentId,
	b.contentType,
	b.courseID,
	b.ASSESSMENT_UUID,
	b.ASSESSMENT_NAME,
	b.PLANID,
	b.email
FROM
	DVS.CURRENT_STATE.SKILLS_SKILLIQ_V3_ASSESSMENTSESSION a
LEFT JOIN gap_module_details b ON
	a.ASSESSMENTID = b.ASSESSMENT_UUID
	AND a.ID = b.SKILLASSESSMENTSESSIONID




--list of clips viewed by user along with the viewtime in seconds (Model_Name : NE_CLIPVIEW_FULL)
SELECT 
	USERID AS Userhandle,
    STARTUTC,
    CLIPID,
    VIEWTIMEINSECONDS
FROM SOURCE_SYSTEM.MSSQL.CLIPVIEW_FULL
where STARTUTC > DATEADD(MONTH, -12, CURRENT_DATE())

--Course meta data includes Course,Module and clip details (Model_Name : NE_COURSE_METADATA)
with course_meta as(
    SELECT a.COURSE_ID,
        a.COURSE_TITLE,
        a.COURSE_IS_RETIRED,
        a.COURSE_DURATION_IN_SECONDS as COURSE_LENGTH_SECONDS,
        b.ID as MODULE_ID,
        b.TITLE as MODULE_TITLE,
        c.ID as CLIP_ID,
        c.TITLE as CLIP_TITLE,
        c.DURATION as CLIP_LENGTH_SECONDS,
        SUM(c.DURATION) OVER (PARTITION BY b.ID) as MODULE_LENGTH_SECONDS
    FROM SOURCE_SYSTEM.PRODUCT.COURSE a
        LEFT JOIN silver.video.module b ON b.COURSEID = a.COURSE_ID
        LEFT JOIN silver.video.clip c ON c.MODULEID = b.ID
    GROUP BY 1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9
)
select distinct *
from course_meta

--list of users who not started,started and completed the Module after a skill IQ -Final code (Model_Name : NE_SKILLIQ_GAP_RECOMMENDEDCOURSE_PROGRESS)
WITH gap_module_with_module_data AS (
    SELECT
        a.*,
        b.MODULE_TITLE,
        b.CLIP_ID,
        b.CLIP_TITLE,
        b.COURSE_TITLE,
        b.CLIP_LENGTH_SECONDS,
        b.MODULE_LENGTH_SECONDS
    FROM
        {{ref('NE_SKILLIQ_RECOMMENDED_MODULE')}} a
    LEFT JOIN {{ref('NE_COURSE_METADATA')}} b ON
        a.contentid = b.MODULE_ID
),

gap_module_viewtime AS (
    SELECT
        a.CREATE_DATE,
        a.ASSESSMENT_UUID as skilliq_id,
        a.ASSESSMENT_NAME as SkillIQ,
        a.SKILLASSESSMENTSESSIONID,
        a.USERHANDLE,
        a.PLANID,
        a.email,
        a.COURSEID,
        a.COURSE_TITLE,
        a.contentid,
        a.Module_title,
        a.MODULE_LENGTH_SECONDS,
        count(b.CLIPID),
        count(a.Clip_id),
        SUM(CASE WHEN b.STARTUTC >= a.CREATE_DATE THEN b.VIEWTIMEINSECONDS ELSE 0 END) AS viewtimeinsec,
        CASE
            WHEN SUM(CASE WHEN b.STARTUTC >= a.CREATE_DATE THEN b.VIEWTIMEINSECONDS ELSE 0 END) = 0 THEN 'Not Started'
            WHEN COUNT(DISTINCT b.CLIPID) = COUNT(DISTINCT a.Clip_id) AND viewtimeinsec >= a.MODULE_LENGTH_SECONDS  THEN 'Completed'
            ELSE 'Started'
        END AS Module_Status
    FROM
        gap_module_with_module_data a
    LEFT JOIN {{ref('NE_CLIPVIEW_FULL')}} b ON
        a.Clip_id = b.CLIPID AND a.userhandle = b.Userhandle
    GROUP BY
        1, 2, 3, 4, 5, 6, 7, 8,9,10,11,12
)

SELECT
   DISTINCT  *
FROM
    gap_module_viewtime 


