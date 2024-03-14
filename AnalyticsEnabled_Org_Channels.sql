--Org channels that has Analytics enabled/disabled

SELECT date(to_timestamp(CREATEDAT,3)) AS channel_createdate, 
ID AS channel_id,
NAME AS Channel_Name,
Privacylevel,
Planid,
ANALYTICSENABLED FROM DVS.CURRENT_STATE.SKILLS_CHANNELS_V2_CHANNEL
WHERE 
date(to_timestamp(CREATEDAT,3)) >= '2023-01-01'
AND PRIVACYLEVEL LIKE 'org'
AND ANALYTICSENABLED = FALSE 