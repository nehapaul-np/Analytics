WITH cte1 AS (
    SELECT
        a.CREATE_DATE,
        a.SKILLASSESSMENTSESSIONID,
        a.USERHANDLE,
        a.ID,
        a.CONTENTID,
        a.CONTENTTYPE,
        a.COURSEID,
        b.TITLE AS Module_title,
        c.ID AS Clip_id,
        c.TITLE AS Clip_title
    FROM
        ANALYTICS.SANDBOX.NE_SKILLIQ_RECOMMENDED_MODULE a
    LEFT JOIN SILVER.VIDEO.MODULE b ON
        b.ID = a.CONTENTID
    LEFT JOIN SILVER.VIDEO.CLIP c ON
        c.MODULEID = a.CONTENTID
        AND c.COURSEID = a.COURSEID
    WHERE
        a.USERHANDLE = '2e5c07ae-a4b1-4df4-a297-158a3e6d81a4'
--        AND a.COURSEID = '7d70de87-4066-466b-8be2-e5db345b6d07'
--        AND a.CONTENTID = '5a91f08b-5cf0-41f2-99a4-569fac3ce091'
),

cte2 AS (
    SELECT
        USERID AS Userhandle,
        USEREMAIL,
        STARTUTC,
        CLIPID,
        AUTHORNAME,
        CLIPLENGTHINSECONDS,
        VIEWTIMEINSECONDS,
        MODULEID,
        COURSEID,
        COURSETITLE,
        PLANNAME
    FROM
        SOURCE_SYSTEM.MSSQL.CLIPVIEW_FULL
    WHERE
--        COURSEID = '7d70de87-4066-466b-8be2-e5db345b6d07'
        USERHANDLE = '2e5c07ae-a4b1-4df4-a297-158a3e6d81a4'
),

cte3 AS (
    SELECT
        a.CREATE_DATE,
        a.SKILLASSESSMENTSESSIONID,
        a.USERHANDLE,
        a.CONTENTID AS module_id,
        a.CONTENTTYPE,
        a.COURSEID,
        a.Module_title,
        a.Clip_id,
        a.Clip_title,
        b.USEREMAIL,
        b.PLANNAME,
        b.COURSETITLE,
        MAX(b.CLIPLENGTHINSECONDS) AS Clip_Length,
        SUM(b.VIEWTIMEINSECONDS) AS viewtimeinsec,
        CASE WHEN SUM(b.VIEWTIMEINSECONDS) >= MAX(b.CLIPLENGTHINSECONDS) THEN 'Module Complete' ELSE 'Not Complete' END AS Module_Status
    FROM
        cte1 a
    LEFT JOIN cte2 b ON
        a.Clip_id = b.CLIPID
    WHERE
        b.STARTUTC >= a.CREATE_DATE
    GROUP BY
        a.CREATE_DATE,
        a.SKILLASSESSMENTSESSIONID,
        a.USERHANDLE,
        a.ID,
        a.CONTENTID,
        a.CONTENTTYPE,
        a.COURSEID,
        a.Module_title,
        a.Clip_id,
        a.Clip_title,
        b.USEREMAIL,
        b.PLANNAME,
        b.COURSETITLE
)

SELECT
    DISTINCT *
FROM
    cte3;
