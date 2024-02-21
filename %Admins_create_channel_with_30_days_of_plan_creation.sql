--plan start data
WITH planstart AS (
SELECT
	to_timestamp(CREATEDAT,
	3) AS plan_createdate,
	ID AS plan_id,
	to_timestamp(EXPIRESAT,
	3) AS plan_expiredate,
	to_timestamp(UPDATEDAT,
	3) AS PLAN_updatedate
FROM
	DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLAN
	),
	
--admin for a PLAN 
admin AS(
SELECT
	a.PLANNAME,
	a.HANDLE,
	a.ISADMIN,
	b.ID AS leader_id,
	to_timestamp(b.CREATEDAT,
	3) AS admin_addeddate
FROM
	SOURCE_SYSTEM.ETL.PLAN_MEMBERS a
INNER JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V2_LEADER b ON
	a.HANDLE = b.USERHANDLE
	AND a.PLANNAME = b.PLANID
WHERE
	b.ID IS NOT NULL
	AND a.ISADMIN = 1
),

--channel created
channel_createdAM AS(
SELECT
	CHANNEL_CREATDATE,
	CHANNEL_ID,
	PLANID,
	USERHANDLE
FROM
	ANALYTICS.SANDBOX.NE_CHANNEL
	--WHERE PRIVACYLEVEL = 'org'
)
--channel created by admin within 30 days of plan creation
SELECT
	a.*,
	b.isadmin,
	b.LEADER_ID,
	c.plan_createdate,
	CASE
		WHEN DATEDIFF('days',
		c.plan_createdate,
		a.CHANNEL_CREATDATE) <= 30 THEN TRUE
		ELSE FALSE
	END AS created_within_30_days
FROM
	channel_createdAM a
LEFT JOIN admin b ON
	a.USERHANDLE = b.HANDLE
	AND a.PLANID = b.PLANNAME
LEFT JOIN planstart c ON
	c.plan_id = a.PLANID
WHERE
	b.isadmin = 1
	AND b.admin_addeddate >= c.plan_createdate
	AND a.CHANNEL_CREATDATE >= c.plan_createdate
GROUP BY
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8;
