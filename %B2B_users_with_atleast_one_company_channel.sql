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