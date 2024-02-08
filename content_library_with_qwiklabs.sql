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
