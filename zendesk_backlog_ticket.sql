{# WITH RECURSIVE DateRangeCTE AS (
SELECT
	DISTINCT TICKET_ID,
	MIN(date(UPDATED)) OVER(PARTITION BY TICKET_ID) AS start_date,
	MAX(date(UPDATED)) OVER(PARTITION BY TICKET_ID) AS end_date
FROM
	SOURCE_SYSTEM.ZENDESK.TICKET_FIELD_HISTORY
WHERE
		TICKET_ID LIKE 1606952
	AND 
	FIELD_NAME LIKE 'status'
UNION ALL
SELECT
	TICKET_ID,
	start_date + INTERVAL '1 day' AS start_date,
	end_date
FROM
	DateRangeCTE
WHERE
	start_date + INTERVAL '1 day' <= end_date
),

ticket AS (
SELECT
	TICKET_ID,
	date(UPDATED) AS ticket_status_date,
	UPDATED AS Date_tim,
	VALUE
FROM
	SOURCE_SYSTEM.ZENDESK.TICKET_FIELD_HISTORY
WHERE
		TICKET_ID LIKE 1606952
	AND 
	FIELD_NAME LIKE 'status'
),

final_ticket_status AS (
SELECT
	TICKET_ID,
	START_DATE,
	END_DATE,
	status,
	Date_tim,
	MAX(status) OVER(PARTITION BY TICKET_ID,
	grouper ) AS Status_n
FROM
	(
	SELECT
		a.*,
		b.VALUE AS status,
		b.Date_tim,
		COUNT(b.VALUE) OVER (PARTITION BY a.ticket_id
	ORDER BY
		a.start_date,
		b.Date_tim) AS grouper
	FROM
		DateRangeCTE a
	LEFT JOIN ticket b ON
		a.TICKET_ID = b.TICKET_ID
		AND a.START_DATE = b.ticket_status_date) AS grouped),
		
fnl_table AS (
SELECT
	a.*,
	b.GROUP_ID,
	c."NAME" AS group_name
FROM
	final_ticket_status a
LEFT JOIN FIVETRAN.ZENDESK.TICKET b ON
	a.ticket_id = b.ID
LEFT JOIN FIVETRAN.ZENDESK."GROUP" c ON	
	b.GROUP_ID = c.ID
WHERE
	c."NAME" IN ('Blocks', 'Billing Issues: Temp Group', 'Cloud Operations', 'Cloud SPSR', 'Cloud Tier One', 'GDPR', 'Piracy', 'Skills Content', 'Skills Escalations', 'Skills Support', 'Skills Technical Support', 'Support Coordinators')),

	
--SELECT * FROM fnl_table;

--two keep the latest record if there is multiple status change in a same day
RankedRows AS (
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY START_DATE
ORDER BY
	DATE_TIM DESC) AS RowRank,
FROM
	fnl_table
)

SELECT
*
FROM
	RankedRows
WHERE
	RowRank = 1; #}



--final script
WITH DateRangeCTE AS (
    SELECT
        TICKET_ID,
        MIN(DATE((UPDATED))) AS start_date,
        MAX(DATE((UPDATED))) AS end_date
    FROM
        SOURCE_SYSTEM.ZENDESK.TICKET_FIELD_HISTORY
    WHERE
FIELD_NAME = 'status'
    GROUP BY
        TICKET_ID
),

TicketStatus AS (
    SELECT
        TICKET_ID,
        DATE((UPDATED)) AS ticket_status_date,
        UPDATED AS Date_tim,
        VALUE AS status
    FROM
        SOURCE_SYSTEM.ZENDESK.TICKET_FIELD_HISTORY
    WHERE
FIELD_NAME = 'status'
),

FinalTicketStatus AS (
    SELECT
        d.TICKET_ID,
        d.start_date,
        d.end_date,
        t.status,
        t.Date_tim,
        MAX(t.status) OVER (PARTITION BY d.TICKET_ID, grouper) AS Status_n
    FROM
        DateRangeCTE d
    LEFT JOIN (
        SELECT
            t.*,
            ROW_NUMBER() OVER (PARTITION BY t.TICKET_ID, DATE((t.Date_tim)) ORDER BY t.Date_tim DESC) AS grouper
        FROM
            TicketStatus t
    ) t ON d.TICKET_ID = t.TICKET_ID AND DATE((t.Date_tim)) BETWEEN d.start_date AND d.end_date
),

fnl_table AS (
    SELECT
        f.*,
        t.GROUP_ID,
        T.TYPE,
        T.PROBLEM_ID,
        T.SUBJECT,
        T.DESCRIPTION,
        T.PRIORITY,
        REPLACE(CONCAT('https://pluralsight.zendesk.com/agent/tickets/', SUBSTRING(T.url, CHARINDEX('/tickets/', T.url) + 9, LEN(T.url))), '.json', '') AS zendesk_url,
        g."NAME" AS group_name
    FROM
        FinalTicketStatus f
    LEFT JOIN FIVETRAN.ZENDESK.TICKET t ON f.TICKET_ID = t.ID
    LEFT JOIN FIVETRAN.ZENDESK."GROUP" g ON t.GROUP_ID = g.ID
    WHERE
        g."NAME" IN ('Blocks', 'Billing Issues: Temp Group', 'Cloud Operations', 'Cloud SPSR', 'Cloud Tier One', 'GDPR', 'Piracy', 'Skills Content', 'Skills Escalations', 'Skills Support', 'Skills Technical Support', 'Support Coordinators')
),

RankedRows AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.start_date ORDER BY r.Date_tim DESC) AS RowRank
    FROM
        fnl_table r
)

SELECT * FROM RankedRows;
