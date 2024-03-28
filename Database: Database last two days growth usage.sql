--Database Space Stats
if object_id('tempdb..##tmp_growthLog') is not null drop table ##tmp_growthLog
go
DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2;
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.',@filename);
SET @ec = CHARINDEX('_',@filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
-- set filename without rollover number
SET @filename = @bfn + @efn
-- process all trace files
SELECT 
ftg.StartTime
,te.name AS EventName
,DB_NAME(ftg.databaseid) AS DatabaseName 
,ftg.Filename
,(ftg.IntegerData*8)/1024.0 AS GrowthMB 
,(ftg.duration/1000)AS DurMS
into ##tmp_growthLog
FROM ::fn_trace_gettable(@filename, DEFAULT) AS ftg 
INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id 
WHERE (ftg.EventClass = 92 -- Date File Auto-grow
OR ftg.EventClass = 93) -- Log File Auto-grow
ORDER BY ftg.StartTime
--select * from ##tmp_growthLog
----where FILENAME like 'FirmLog%'
--order by StartTime desc
select Duration,DatabaseName,Filename,EventName,TotalGrowthMB,totalDurationMs from (
select 'Growth in Last Hour' as Duration, DatabaseName,Filename,EventName,sum(GrowthMB) as TotalGrowthMB,sum(DurMS) as totalDurationMs,1 as id 
from ##tmp_growthLog
where starttime > dateadd (HH,-1,getdate())
group by DatabaseName,FileName,EventName
union all
select 'Growth in Last 2 days' as Duration, DatabaseName,Filename,EventName,sum(GrowthMB) as TotalGrowthMB,sum(DurMS) as totalDurationMs ,2 as id 
from ##tmp_growthLog
where starttime > dateadd (DD,-2,getdate())
group by DatabaseName,FileName,EventName
) a
order by id,DatabaseName,FileName,EventName desc
--Track Database Growth in last 2 days
if object_id('tempdb..##tmp_growthLog') is not null drop table ##tmp_growthLog
go
DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2;
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.',@filename);
SET @ec = CHARINDEX('_',@filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
-- set filename without rollover number
SET @filename = @bfn + @efn
-- process all trace files
SELECT 
ftg.StartTime
,te.name AS EventName
,DB_NAME(ftg.databaseid) AS DatabaseName 
,ftg.Filename
,(ftg.IntegerData*8)/1024.0 AS GrowthMB 
,(ftg.duration/1000)AS DurMS,SPID
into ##tmp_growthLog
FROM ::fn_trace_gettable(@filename, DEFAULT) AS ftg 
INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id 
WHERE (ftg.EventClass = 92 -- Date File Auto-grow
OR ftg.EventClass = 93) -- Log File Auto-grow
ORDER BY ftg.StartTime
select EventName, DatabaseName, Filename, GrowthMB, StartTime, durms as DurationMS, SPID from ##tmp_growthLog
----where FILENAME like 'FirmLog%'
order by StartTime desc
