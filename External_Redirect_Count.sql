--Request Description
--Total number of external redirects to any brand by a user
--Jira Ticket : https://pluralsight.atlassian.net/browse/SSPA-386

--This CTE contains all external links
WITH links_table AS(
SELECT
	date(to_timestamp(CREATEDAT,
	3)) AS Create_Date,
	date(to_timestamp(UPDATEDAT,
	3)) AS Update_Date,
	TITLE,
	TAGS,
	SOURCE,
	CONTENTTYPE,
	ID AS content_id
FROM
	DVS.CURRENT_STATE.SKILLS_CONTENTFORMATLINKS_V1_LINK l
),
	
--Access details for the links by a user
user_access_table AS (
SELECT
	date(to_timestamp(ACCESSEDAT,
	3)) AS access_date,
	LINKID,
	PARTNER,
	ID,
	USERHANDLE
FROM
	DVS.CURRENT_STATE.SKILLS_LTIINTEGRATION_V1_PARTNERCONTENTACCESSED
)

SELECT
	u.USERHANDLE,
	l.content_id,
	l.TITLE,
	l.SOURCE,
	l.CONTENTTYPE,
	l.Create_Date AS Content_CreateDate,
	l.Update_Date AS Content_UpdateDate,
	COUNT(DISTINCT u.ID) AS Redirect_Count
FROM
	links_table l
LEFT JOIN
    user_access_table u ON
	l.content_id = u.LINKID
GROUP BY
	1,
	2,
	3,
	4,
	5,
	6,
	7;


--Request Description
--Total number of external redirects by year
--Jira Ticket : https://pluralsight.atlassian.net/browse/SSPA-389

--External Redirect count by year
SELECT
	YEAR(to_timestamp(ACCESSEDAT,
	3)) AS Access_Year,
	COUNT(DISTINCT ID) AS Redirect_Count
FROM
	DVS.CURRENT_STATE.SKILLS_LTIINTEGRATION_V1_PARTNERCONTENTACCESSED
GROUP BY
	1;

--Overall Redirect count
  SELECT
	COUNT(DISTINCT ID) As Redirect_count
FROM
	DVS.CURRENT_STATE.SKILLS_LTIINTEGRATION_V1_PARTNERCONTENTACCESSED ;