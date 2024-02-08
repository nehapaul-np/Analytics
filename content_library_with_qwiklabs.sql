--List of all library that contains the qwiklabs contents.
WITH qwiklab_library_content AS (
SELECT
	a.CONTENTID,
	a.CONTENTTYPE
FROM
	DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARYCONTENT a
WHERE
	a.LIBRARYID IN ('118694ca-28f5-4236-8cb3-1e08f5912c39', '8b01ea91-a344-494b-b26d-7e60fe8dda51')
),

other_library_with_Qwiklabs AS(
SELECT
	a.CONTENTID,
	a.CONTENTTYPE,
	b.LIBRARYID,
	ARRAY_to_string(c.TAGS,
	',') AS Tags
FROM
	qwiklab_library_content a
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARYCONTENT b
ON
	a.CONTENTID = b.CONTENTID
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTFORMATLINKS_V1_LINK c
ON
	a.CONTENTID = c.ID
{# WHERE
	b.LIBRARYID IS NULL
	OR b.LIBRARYID NOT IN ('118694ca-28f5-4236-8cb3-1e08f5912c39', '8b01ea91-a344-494b-b26d-7e60fe8dda51')), #}
	),
fnl AS(
SELECT
	CONTENTID,
	CONTENTTYPE,
	LIBRARYID,
	CASE
		WHEN Tags LIKE '%Embedded%'
			AND Tags LIKE '%Standalone%' THEN 'Embedded and Standalone'
			WHEN Tags LIKE '%Embedded%' THEN 'Embedded'
			WHEN Tags LIKE '%Standalone%' THEN 'Standalone'
			ELSE 'Unknown'
		END AS Embedded_Standalone_Status
	FROM
		other_library_with_Qwiklabs
)
    
SELECT
	DISTINCT a.LIBRARYID,
	b.TITLE,
	array_agg(DISTINCT a.Embedded_Standalone_Status) AS Tags
FROM
	fnl a
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARY b ON
	a.LIBRARYID = b.ID
GROUP BY
	1,
	2



--version two includes the count of distinct contents for each Tag and ContentType
--List of Qwiklabs contents from 2 provided Library.
WITH qwiklab_library_content AS (
SELECT
	a.CONTENTID,
	a.CONTENTTYPE
FROM
	DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARYCONTENT a
WHERE
	a.LIBRARYID IN ('118694ca-28f5-4236-8cb3-1e08f5912c39', '8b01ea91-a344-494b-b26d-7e60fe8dda51')
	-- qwiklab content library
),

other_library_with_Qwiklabs AS(
SELECT
	a.CONTENTID,
	a.CONTENTTYPE,
	b.LIBRARYID,
	ARRAY_to_string(c.TAGS,
	',') AS Tags,
	c.CONTENTTYPE AS m_contenttype,
	c.SOURCE
FROM
	qwiklab_library_content a
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARYCONTENT b
ON
	a.CONTENTID = b.CONTENTID
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTFORMATLINKS_V1_LINK c
ON
	a.CONTENTID = c.ID
WHERE
	b.LIBRARYID IS NULL
	OR b.LIBRARYID NOT IN ('118694ca-28f5-4236-8cb3-1e08f5912c39', '8b01ea91-a344-494b-b26d-7e60fe8dda51')
	),
	
fnl AS(
SELECT
	CONTENTID,
	CONTENTTYPE,
	LIBRARYID,
	CASE
		WHEN Tags LIKE '%Embedded%'
			AND Tags LIKE '%Standalone%' THEN 'Embedded and Standalone'
			WHEN Tags LIKE '%Embedded%' THEN 'Embedded'
			WHEN Tags LIKE '%Standalone%' THEN 'Standalone'
			ELSE 'Unknown'
		END AS Embedded_Standalone_Status,
		m_contenttype,
		SOURCE
	FROM
		other_library_with_Qwiklabs
)
	
SELECT
	DISTINCT a.LIBRARYID,
	b.TITLE AS Library_Title,
	array_agg(DISTINCT a.Embedded_Standalone_Status) AS Tags,
	COUNT(DISTINCT a.CONTENTID) AS content_count,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Standalone' THEN a.CONTENTID END) AS Standalone,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Embedded' THEN a.CONTENTID END) AS Embedded,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Standalone' AND a.M_CONTENTTYPE = 'Lab' THEN a.CONTENTID END) AS standalone_lab,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Embedded' AND a.M_CONTENTTYPE = 'Lab' THEN a.CONTENTID END) AS embedded_lab,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Standalone' AND a.M_CONTENTTYPE = 'Reading' THEN a.CONTENTID END) AS standalone_reading,
	COUNT(DISTINCT CASE WHEN a.EMBEDDED_STANDALONE_STATUS = 'Embedded' AND a.M_CONTENTTYPE = 'Reading' THEN a.CONTENTID END) AS embedded_reading
FROM
	fnl a
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARY b ON
	a.LIBRARYID = b.ID
GROUP BY
	1,
	2;

--version 3 to fetch the list of Library that includes contenttype as 'links'
WITH cte AS (
    SELECT
        ID,
        SOURCE,
        ARRAY_to_string(TAGS, ',') AS Tags
    FROM
        DVS.CURRENT_STATE.SKILLS_CONTENTFORMATLINKS_V1_LINK
),

cte2 AS (
    SELECT
        ID,
        SOURCE,
        Tags,
        CASE
            WHEN Tags LIKE '%Standalone%' AND Tags LIKE '%Qwiklabs%' THEN 'Qwiklabs_standalone'
            WHEN SOURCE IN ('gcp', 'Qwiklabs') AND Tags LIKE '%Embedded%' THEN 'All Google Content Embedded'
            WHEN Tags LIKE '%Standalone%' AND Tags LIKE '%Cyber Vista%' THEN 'Cyber_Vista_Standalone'
            WHEN Tags LIKE '%IBM%' OR SOURCE LIKE '%IBM%' THEN 'IBM_Embedded'
            WHEN Tags LIKE '%Next Tech%' THEN 'Code_Labs'
            ELSE 'Unknown'
        END AS Embedded_Standalone_Status
    FROM
        cte
),

fnl AS (
    SELECT
        a.*,
        b.LIBRARYID,
        c.TITLE
    FROM
        cte2 a
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARYCONTENT b ON
        a.ID = b.CONTENTID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARY c ON
        b.LIBRARYID = c.ID
    WHERE
        Embedded_Standalone_Status NOT LIKE 'Unknown'
)

SELECT
    a.LIBRARYID,
    b.TITLE AS Library_Name,
    COUNT(DISTINCT a.ID) AS link_count, 
    COUNT(DISTINCT CASE WHEN a.Embedded_Standalone_Status = 'Qwiklabs_standalone' THEN a.ID END) AS Qwiklabs_standalone_Count,
    COUNT(DISTINCT CASE WHEN a.Embedded_Standalone_Status = 'All Google Content Embedded' THEN a.ID END) AS All_Google_Content_Embedded_Count,
    COUNT(DISTINCT CASE WHEN a.Embedded_Standalone_Status = 'Cyber_Vista_Standalone' THEN a.ID END) AS Cyber_Vista_Standalone_Count,
    COUNT(DISTINCT CASE WHEN a.Embedded_Standalone_Status = 'IBM_Embedded' THEN a.ID END) AS IBM_Embedded_Count,
    COUNT(DISTINCT CASE WHEN a.Embedded_Standalone_Status = 'Code_Labs' THEN a.ID END) AS Code_Labs_Count
FROM
fnl a 
LEFT JOIN DVS.CURRENT_STATE.SKILLS_CONTENTLIBRARIES_V3_LIBRARY b ON
a.LIBRARYID = b.ID 
WHERE a.LIBRARYID IS NOT NULL 
GROUP BY
    a.LIBRARYID, b.TITLE;
