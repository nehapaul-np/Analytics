--TF Insight for 'kpmg-usa-llp-030aa'
--Program Score by team
WITH PROGRAMSCORE as
(
	select distinct USERHANDLE
		   ,PROGRAMNAME
		   ,PROGRAMID
		   ,PLANID
		   ,PROGRAMSCORE
		   ,NUMPROGRAMAVAILABLESUBJECTS
		   ,NUMUSERSUCCESSFULSUBJECTSPASSED
		   ,date(to_timestamp(createdat,3)) as programscore_created_date
		   ,date(to_timestamp(LASTSUCCESSFULSUBJECTPASSEDAT,3)) as lastpasssubject_date
	FROM DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V7_PROGRAMSCORE	
WHERE planid like 'kpmg-usa-llp-030aa'
),

team_details AS (
    SELECT
        p1.PLANUSERID,
        f1.TeamID,
        t2.ID AS team_id,
        t2."NAME" AS team_name,
        t2.PLANID,
        t3.USERHANDLE
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p1
    LEFT JOIN (
        SELECT
            p2.PLANUSERID,
            PARSE_JSON(value):teamId::varchar AS TeamID
        FROM
            DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p2,
            LATERAL FLATTEN(input => p2.teams)
    ) f1 ON p1.PLANUSERID = f1.PLANUSERID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_TEAM t2 ON f1.TeamID = t2.ID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSER t3 ON p1.PLANUSERID = t3.ID
    WHERE t2.PLANID LIKE 'kpmg-usa-llp-030aa'
),

fnl AS (
    SELECT
        ta.*,
        td.TeamID,
        td.team_name
    FROM
        PROGRAMSCORE ta
    LEFT JOIN
        team_details td
    ON
        ta.USERHANDLE = td.USERHANDLE
)

SELECT * FROM fnl;



***********************************************************************************************************************************


--TF assesment details by team
WITH tf_assessment AS (
    SELECT
        DISTINCT userid,
        id,
        programname,
        planid,
        trim(subjectname) AS subjectname,
        SUBJECTATTEMPTCOUNT,
        status,
        passfailskipped,
        preorpostcheck,
        date(to_timestamp(createdat, 3)) AS assess_created_date,
        date(to_timestamp(startedon, 3)) AS assess_started_date,
        date(to_timestamp(completedon, 3)) AS assess_completed_date
    FROM
        DVS.CURRENT_STATE.SKILLS_PLAN_ANALYTICS_V9_CRITERIONREFERENCEDASSESSMENTS
    WHERE
        planid ILIKE 'kpmg-usa-llp-030aa'
    ORDER BY
        2, 3, 4
),

team_details AS (
    SELECT
        p1.PLANUSERID,
        f1.TeamID,
        t2.ID AS team_id,
        t2."NAME" AS team_name,
        t2.PLANID,
        t3.USERHANDLE
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p1
    LEFT JOIN (
        SELECT
            p2.PLANUSERID,
            PARSE_JSON(value):teamId::varchar AS TeamID
        FROM
            DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p2,
            LATERAL FLATTEN(input => p2.teams)
    ) f1 ON p1.PLANUSERID = f1.PLANUSERID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_TEAM t2 ON f1.TeamID = t2.ID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSER t3 ON p1.PLANUSERID = t3.ID
    WHERE t2.PLANID LIKE 'kpmg-usa-llp-030aa'
),

fnl AS (
    SELECT
        ta.*,
        td.TeamID,
        td.team_name
    FROM
        tf_assessment ta
    LEFT JOIN
        team_details td
    ON
        ta.userid = td.USERHANDLE
)
    
SELECT * FROM fnl;


**********************************************************************************************************************************

--Team Licence redemption
WITH product_catalog AS (
    SELECT
        name,
        SKU,
        STATUS,
        "TYPE",
        CUSTOMER_TYPE,
        category,
        id
    FROM
        DVS.CURRENT_STATE.FIN_PRODUCT_CATALOG_V1_PRODUCT
    WHERE
        SKU IN (
            'SK-TECH-FOUND-ADD',
            'Tech-Foundations-HUB',
            'SLICE-KPMG-LL',
            'SLICE-KPMG-LL-ADD',
            'TQ-GTM',
            'TQ2-GTM-ADDON',
            'TQ2-GTM-BASE',
            'TQ2-Lloyds-BASE',
            'TQ2-LLOYDS-ADDON',
            'ACN-ENT-TQ-ADD',
            'ENT-LIMITED-ACCENTURETQ'
        )
),
plan_with_products AS (
    SELECT
        id AS plan_id,
        ispilot,
        DATE(TO_TIMESTAMP(createdat, 3)) AS createdat,
        DATE(TO_TIMESTAMP(updatedat, 3)) AS updatedat,
        f.value['productId']::STRING AS product_id,
        f.value['productOptionId']::STRING AS product_option_id,
        f.value['totalLicenseCount']::INT AS total_license_count
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLAN t,
        LATERAL FLATTEN(INPUT => t.products) f
),
plan_with_user_status AS (
    SELECT
        userhandle,
        id AS planuserid,
        planid,
        ispending,
        pendingemail,
        DATE(TO_TIMESTAMP(updatedat, 3)) AS updatedat
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSER pu
),
learners_with_products AS (
    SELECT
        planuserid,
        f.value['productId']::STRING AS product_id,
        DATE(TO_TIMESTAMP(updatedat, 3)) AS updatedat
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_LEARNER t,
        LATERAL FLATTEN(INPUT => t.products) f
),
team_details AS (
    SELECT
        p1.PLANUSERID,
        f1.TeamID,
        t2.ID AS team_id,
        t2."NAME" AS team_name,
        t2.PLANID,
        t3.USERHANDLE
    FROM
        DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p1
    LEFT JOIN (
        SELECT
            p2.PLANUSERID,
            PARSE_JSON(value):teamId::VARCHAR AS TeamID
        FROM
            DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSERTEAMHIERARCHY p2,
            LATERAL FLATTEN(INPUT => p2.teams)
    ) f1 ON p1.PLANUSERID = f1.PLANUSERID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_TEAM t2 ON f1.TeamID = t2.ID
    LEFT JOIN DVS.CURRENT_STATE.SKILLS_PLANS_V1_PLANUSER t3 ON p1.PLANUSERID = t3.ID
    WHERE
        t2.PLANID LIKE 'kpmg-usa-llp-030aa'
),
product_plans_teams_combine AS (
    SELECT
        pu.planid,
        pp.ispilot,
        pp.product_id,
        pc.name,
        pc.SKU,
        pc.STATUS,
        pc."TYPE",
        pc.CUSTOMER_TYPE,
        pc.category,
        td.team_id,
        td.team_name,
        pp.total_license_count AS total_license_count,
        COUNT(DISTINCT pu.userhandle) AS num_users_redeemed
    FROM
        plan_with_user_status pu
    INNER JOIN learners_with_products le ON pu.planuserid = le.planuserid
    INNER JOIN plan_with_products pp ON le.product_id = pp.product_id AND pu.planid = pp.plan_id
    INNER JOIN product_catalog pc ON pp.product_id = pc.id
    LEFT JOIN team_details td ON pu.userhandle = td.USERHANDLE
    WHERE
        pu.planid LIKE 'kpmg-usa-llp-030aa'
    GROUP BY
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,12
)
SELECT *
FROM
    product_plans_teams_combine