-- Recommended module
WITH cte1 AS (
    SELECT a.*,
        b.TITLE AS Module_title,
        c.ID AS Clip_id,
        c.TITLE AS Clip_title
    FROM ANALYTICS.SANDBOX.NE_SKILLIQ_RECOMMENDED_MODULE a
        LEFT JOIN SILVER.VIDEO.MODULE b ON b.ID = a.CONTENTID
        LEFT JOIN SILVER.VIDEO.CLIP c ON c.MODULEID = a.CONTENTID
        AND c.COURSEID = a.COURSEID
    WHERE a.USERHANDLE LIKE '2e5c07ae-a4b1-4df4-a297-158a3e6d81a4'
        AND a.COURSEID LIKE '7d70de87-4066-466b-8be2-e5db345b6d07'
        AND a.CONTENTID LIKE '5a91f08b-5cf0-41f2-99a4-569fac3ce091'
)
SELECT DISTINCT *
FROM cte1

--Module duration
WITH cte1 AS (
    SELECT MODULEID,
        COURSEID,
        COURSENAME,
        CLIPID,
        CLIPLENGTHINSECONDS
    FROM SOURCE_SYSTEM.PRODUCT.COURSE_PROGRESS_DETAIL
    WHERE COURSEID = '7d70de87-4066-466b-8be2-e5db345b6d07'
        AND ARCHIVEDCLIP = 'Active Clip'
        AND MODULEID LIKE '5a91f08b-5cf0-41f2-99a4-569fac3ce091'
),
cte2 AS(
    SELECT DISTINCT *
    FROM cte1
)
SELECT MODULEID,
    COURSEID,
    COURSENAME,
    SUM(CLIPLENGTHINSECONDS) AS Module_length
FROM cte2
GROUP BY 1,
    2,
    3 
    
--Module & Clip level Watch duration
    WITH cte1 AS (
        SELECT date(LASTWATCHUTC) AS watchdate,
            USERHANDLE,
            MODULEID,
            CLIPID,
            TOTALVIEWTIMEINSECONDS
        FROM SOURCE_SYSTEM.PRODUCT.COURSE_PROGRESS_DETAIL
        WHERE COURSEID = '7d70de87-4066-466b-8be2-e5db345b6d07'
            AND ARCHIVEDCLIP = 'Active Clip'
            AND MODULEID LIKE '5a91f08b-5cf0-41f2-99a4-569fac3ce091'
    ),
    cte2 AS(
        SELECT DISTINCT *
        FROM cte1
    )
SELECT watchdate,
    MODULEID,
    USERHANDLE,
    CLIPID,
    SUM(TOTALVIEWTIMEINSECONDS) AS View_time
FROM cte2
WHERE USERHANDLE LIKE '2e5c07ae-a4b1-4df4-a297-158a3e6d81a4'
GROUP BY 1,
    2,
    3,
    4 
    
--Module & Clip level Watch duration along with clip length
    WITH cte1 AS (
        SELECT date(LASTWATCHUTC) AS watchdate,
            USERHANDLE,
            MODULEID,
            CLIPID,
            TOTALVIEWTIMEINSECONDS,
            CLIPLENGTHINSECONDS
        FROM SOURCE_SYSTEM.PRODUCT.COURSE_PROGRESS_DETAIL
        WHERE COURSEID = '7d70de87-4066-466b-8be2-e5db345b6d07'
            AND ARCHIVEDCLIP = 'Active Clip'
            AND MODULEID LIKE '5a91f08b-5cf0-41f2-99a4-569fac3ce091'
    ),
    cte2 AS(
        SELECT DISTINCT *
        FROM cte1
    )
SELECT watchdate,
    MODULEID,
    USERHANDLE,
    CLIPID,
    SUM(TOTALVIEWTIMEINSECONDS) AS View_time,
    SUM(CLIPLENGTHINSECONDS) AS Module_length
FROM cte2
WHERE USERHANDLE LIKE '2e5c07ae-a4b1-4df4-a297-158a3e6d81a4'
GROUP BY 1,
    2,
    3,
    4

--next step to add the clip watch to the recommended