use msdb;
with sjh as (select * from sysjobhistory union all select * from sysjobhistoryall)
select j.name, js.step_id, js.step_name, js.database_name, js.command,
sjh.sql_message_id, sjh.sql_severity, sjh.message, sjh.run_status, sjh.run_date, sjh.run_time, sjh.run_duration, sjh.StartTime, sjh.EndTime
from sysjobs j inner join sjh on j.job_id = sjh.job_id inner join sysjobsteps js on j.job_id = js.job_id and sjh.step_id = js.step_id
where 1=1 -- to allow for easier commenting out of other lines
and sjh.run_status not in (1, 3, 4) -- success criteria
and dbo.agent_datetime(sjh.run_date, sjh.run_time) >= '2023-08-01' 
and j.enabled = 1
and j.name = 'Distribution clean up: distribution'
order by j.name, sjh.starttime, sjh.step_id
===
0 = Failed
1 = Succeeded
2 = Retry
3 = Canceled
4 = In Progress
