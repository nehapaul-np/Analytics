--All users including B2B & B2C
WITH plan_user_count AS (
SELECT
	YEAR(to_timestamp(CREATEDAT,
	3)) AS YEAR,
	COUNT(DISTINCT userhandle) AS PlanUser
FROM
	DVS.CURRENT_STATE.skills_plans_v1_PlanUser
GROUP BY
	1
),
org_channel_user_count AS (
SELECT
	YEAR(Member_added_date) AS YEAR,
	COUNT(DISTINCT userhandle) AS ChannelUser
FROM
	ANALYTICS.SANDBOX.NE_CHANNEL_B2B_USERS_ASSIGNED_WITH_ORG_CHANNEL
WHERE
	PRIVACYLEVEL = 'org'
	AND BUSINESS_TYPE LIKE 'B2B'
GROUP BY
	1
)

SELECT
	a.YEAR,
	a.PlanUser,
	b.ChannelUser,
	ROUND((CAST(b.ChannelUser AS DECIMAL) / NULLIF(a.PlanUser, 0)) * 100) AS B2BUserPercentage
FROM
	plan_user_count a
JOIN org_channel_user_count b ON
	a.YEAR = b.YEAR
WHERE
	a.YEAR > 2021;


--Final Version Includes only the B2B Customers from the Plan User table
WITH plan_user_count AS (
WITH B2B_Plans AS (
SELECT
	DISTINCT plan_id
FROM
	ANALYTICS.CERTIFIED.B2B_SUBSCRIPTIONS
),

cte2 AS (
SELECT
	DATE(TO_TIMESTAMP(a.CREATEDAT,
	3)) AS memberadded_date,
	COALESCE(a.USERHANDLE,
	a.PENDINGEMAIL) AS USERHANDLE,
	a.PLANID
FROM
	DVS.CURRENT_STATE.skills_plans_v1_PlanUser a
WHERE
	a.PLANID IN (
	SELECT
		plan_id
	FROM
		B2B_Plans))
		
SELECT
	YEAR(memberadded_date) AS yeardate,
	COUNT(DISTINCT USERHANDLE) AS b2bplanuser
FROM
	cte2
GROUP BY
	1
),

org_channel_user_count AS (
SELECT
	YEAR(Member_added_date) AS YEAR,
	COUNT(DISTINCT userhandle) AS ChannelUser
FROM
	ANALYTICS.SANDBOX.NE_CHANNEL_B2B_USERS_ASSIGNED_WITH_ORG_CHANNEL
WHERE
	PRIVACYLEVEL = 'org'
	AND BUSINESS_TYPE LIKE 'B2B'
GROUP BY
	1
)

SELECT
	a.yeardate,
	a.b2bplanuser,
	b.ChannelUser,
	ROUND((CAST(b.ChannelUser AS DECIMAL) / NULLIF(a.b2bplanuser, 0)) * 100) AS B2BUserPercentage
FROM
	plan_user_count a
JOIN org_channel_user_count b ON
	a.yeardate = b.YEAR
WHERE
	a.yeardate > 2021;
