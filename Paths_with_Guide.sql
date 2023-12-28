--Request Description
--List of paths that contains the Guide contents
--Jira Ticket : https://pluralsight.atlassian.net/browse/SSPA-393

--Catalog of Published Paths Featuring Guides
SELECT
	b.PATHID,
	c.TITLE AS path_title,
	c.TYPE AS path_type,
	c.STATUS AS path_status,
	a.CONTENTTYPE,
	a.CONTENTID,
	d.TITLE AS Guide_Title
FROM
	DVS.CURRENT_STATE.skills_paths_v2_pathLevelContent a
LEFT JOIN DVS.CURRENT_STATE.skills_paths_v2_pathLevel b ON
	b.ID = a.PATHLEVELID
LEFT JOIN DVS.CURRENT_STATE.skills_paths_v2_path c ON
	c.ID = b.PATHID
LEFT JOIN DVS.CURRENT_STATE.SKILLS_GUIDES_V2_GUIDE D ON
	D.ID = a.CONTENTID 
WHERE
	a.CONTENTTYPE LIKE 'guide' AND c.STATUS = 'published';