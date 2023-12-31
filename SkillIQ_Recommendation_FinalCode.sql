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
