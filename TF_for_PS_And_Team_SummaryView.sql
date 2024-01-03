--TF for PS view And TF Team Summary
--TF for PS Internal Employee Overview
WITH ps_users AS
(
SELECT
	worker AS NAME,
	exec_org_new AS org,
	cost_center AS team,
	supervisory_org,
	employee_email,
	id.HANDLE
FROM
	analytics.sandbox.ne_ps_users_teams ps
LEFT JOIN GOLD.INTEGRATION."USER" id ON
	id.email = ps.employee_email
),

topic_details_pass AS
(
SELECT
	DISTINCT userhandle,
	CASE
		WHEN count (DISTINCT crtopicname) >= '3' THEN '1'
		ELSE '0'
	END AS flg_3plus_topic_passed
FROM
	DVS.CURRENT_STATE.SKILLS_CRITERIONREF_V2_USERCOMPLETIONREPORT
WHERE
	PASSFAILSKIPPED = 'Pass'
GROUP BY
	1
),
users_passed_cloud AS
(
SELECT
	DISTINCT userhandle
FROM
	DVS.CURRENT_STATE.SKILLS_CRITERIONREF_V2_USERCOMPLETIONREPORT
WHERE
	PASSFAILSKIPPED = 'Pass'
	AND trim(crtopicname) = 'Cloud Computing Explained'
),

total_tf_count AS (
SELECT
	DISTINCT userhandle,
	COUNT(DISTINCT crtopicname)  AS tf_count
FROM
	DVS.CURRENT_STATE.SKILLS_CRITERIONREF_V2_USERCOMPLETIONREPORT
WHERE
	PASSFAILSKIPPED = 'Pass' 
	GROUP BY 1
),

users_passed_ai AS
(
SELECT
	DISTINCT userhandle
FROM
	DVS.CURRENT_STATE.SKILLS_CRITERIONREF_V2_USERCOMPLETIONREPORT
WHERE
	PASSFAILSKIPPED = 'Pass'
	AND trim(crtopicname) = 'AI'
),

fnl AS
(
SELECT
	ps.handle,
	ps.employee_email,
	ps.name,
	ps.org,
	ps.team,
	ps.supervisory_org,
	CASE
		WHEN (upc.userhandle IS NOT NULL ) THEN '1'
		ELSE '0'
	END AS flg_cloud_topic_passed,
	CASE
		WHEN (td.flg_3plus_topic_passed = '1') THEN '1'
		ELSE '0'
	END AS flg_3plus_topic_passed,
	CASE
		WHEN (upai.userhandle IS NOT NULL) THEN '1'
		ELSE '0'
	END AS flg_ai_topic_passed,
	COALESCE(tfc.tf_count, 0) AS tf_count
FROM
	ps_users ps
LEFT JOIN topic_details_pass td
	ON
	ps.handle = td.userhandle
LEFT JOIN users_passed_cloud upc
	ON
	ps.handle = upc.userhandle
LEFT JOIN users_passed_ai upai
	ON
	ps.handle = upai.userhandle
LEFT JOIN total_tf_count tfc
	ON
	ps.handle = tfc.userhandle
)

SELECT
	DISTINCT a.employee_email,
	a.HANDLE,
	a.NAME,
	a.ORG,
	a.TEAM,
	a.tf_count,
	a.SUPERVISORY_ORG,
	a.FLG_CLOUD_TOPIC_PASSED,
	a.FLG_3PLUS_TOPIC_PASSED,
	a.FLG_AI_TOPIC_PASSED
FROM
	fnl a

