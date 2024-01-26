--Support Ticket Overview on Customer escalations.
SELECT
	a.KEY AS Issue_Key,
	a.SUMMARY AS Issue_Name,
	b."NAME" AS status,
	CASE
		WHEN b."NAME" IN ('Product - To Do', 'To Do', 'Ready for Dev') THEN 'Planned'
		WHEN b."NAME" IN ('Closed', 'Deployed/Done', 'DONE/DEPLOYED', 'Cancelled') THEN 'Done'
		WHEN b."NAME" IN ('Engineering Refinement', 'In Progress', 'BLOCKED', 'Blocked') THEN 'In Progress'
		WHEN b."NAME" = 'Backlog' THEN 'Backlog'
		ELSE 'Other'
	END AS status_group,
	date(a.CREATED) AS Issue_Createdate,
	date(a.UPDATED) AS Issue_updatedate,
	c."NAME" AS Reporter,
	a.DESCRIPTION,
	D."NAME" AS Project_Name
FROM
	SOURCE_SYSTEM.JIRA."ISSUE" a
LEFT JOIN SOURCE_SYSTEM.JIRA.STATUS b ON
	a.STATUS = b.ID
LEFT JOIN SOURCE_SYSTEM.JIRA."USER" c ON
	a.REPORTER = c.ID
LEFT JOIN SOURCE_SYSTEM.JIRA.PROJECT D ON
	a.PROJECT = D.ID
WHERE
	a.ISSUE_TYPE IN ('12170', '12169', '11924', '12171') --Issue like 'Customer Escalation'