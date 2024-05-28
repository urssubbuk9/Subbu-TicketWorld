USE [msdb]
GO

/****** Object:  Job [Coeo Monitoring - AG preferred replica check]    Script Date: 06/02/2023 16:01:14 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 06/02/2023 16:01:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Coeo Monitoring - AG preferred replica check', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Coeo monitoring - raise error if primary replica is not preferred replica', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check current primary is preferred]    Script Date: 06/02/2023 16:01:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check current primary is preferred', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE	@agName sysname = N''SCOM_AG''
	, @preferredReplicaName nvarchar(256) = N''COEOSQL18'';

IF EXISTS(
	SELECT	1
	FROM	sys.availability_groups AS ag join
		sys.dm_hadr_availability_replica_states AS rs on rs.group_id = ag.group_id
	WHERE	rs.is_local = 1
	and	rs.[role] = 1
	and	ag.[name] = @agName
	and	@@SERVERNAME <> @preferredReplicaName
	)
BEGIN
	RAISERROR(''Current replica is %s. Please arrange failover of %s to preferred replica %s.'', 16, 1, @@SERVERNAME, @agName, @preferredReplicaName)
END', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\$(ESCAPE_SQUOTE(JOBNAME))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(DATE))_$(ESCAPE_SQUOTE(TIME)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'AG preferred replica check - Daily 0700hrs', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230206, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

