WITH cte1 AS (
SELECT
	KEY AS Issue_Key,
	SUMMARY AS Issue_Name,
	DESCRIPTION,
	CASE
		WHEN CHARINDEX('Number of Incidents:', DESCRIPTION) > 0 THEN
                TRIM(SUBSTRING(DESCRIPTION, CHARINDEX('Number of Incidents:', DESCRIPTION) + LEN('Number of Incidents:') + 1, 3))
		ELSE
                NULL
	END AS Incident_Count
FROM
	SOURCE_SYSTEM.JIRA."ISSUE"
WHERE
	ISSUE_TYPE IN ('12170', '12169', '11924', '12171')
),
ExtractNumeric AS (
SELECT
	Issue_Key,
	Issue_Name,
	DESCRIPTION,
	Incident_Count,
	1 AS StartPos,
	SUBSTRING(Incident_Count, 1, 1) AS CurrentChar
FROM
	cte1
UNION ALL
SELECT
	cte1.Issue_Key,
	cte1.Issue_Name,
	cte1.DESCRIPTION,
	cte1.Incident_Count,
	ExtractNumeric.StartPos + 1,
	SUBSTRING(cte1.Incident_Count, ExtractNumeric.StartPos + 1, 1) AS CurrentChar
FROM
	ExtractNumeric
JOIN
        cte1 ON
	ExtractNumeric.Incident_Count = cte1.Incident_Count
WHERE
	ExtractNumeric.StartPos < LEN(cte1.Incident_Count)
)

SELECT
	Issue_Key,
	Issue_Name,
	DESCRIPTION,
	TRY_CAST(MAX(CASE WHEN CurrentChar BETWEEN '0' AND '9' THEN CurrentChar ELSE '' END) AS INT) AS Incident_Count
FROM
	ExtractNumeric
GROUP BY
	1,
	2,
	3;