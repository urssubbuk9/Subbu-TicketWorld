SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Raul Gonzalez
-- Create date: 03/10/2018
-- Description:	Healthcheck: Data and log files on the same physical drives?
--
-- Parameters:
--
-- Log History:	
--
-- =============================================
--=============================================
-- Copyright (C) 2018 Raul Gonzalez, @SQLDoubleG
-- All rights reserved.
--   
-- You may alter this code for your own *non-commercial* purposes. You may
-- republish altered code as long as you give due credit.
--   
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
--
-- =============================================
-- Dependencies:This Section will create on tempdb any dependancy
-- =============================================
USE tempdb
GO
CREATE FUNCTION [dbo].[getDriveFromFullPath](
	@path NVARCHAR(256)
)
RETURNS SYSNAME
AS
BEGIN

	DECLARE @slashPos	INT		= CASE 
									WHEN CHARINDEX( ':', @path ) > 0 THEN CHARINDEX( ':', @path ) 
									WHEN CHARINDEX( '\', @path ) > 0 THEN CHARINDEX( '\', @path ) 
									ELSE NULL 
								END

	RETURN ( CASE WHEN @slashPos IS NULL THEN '\' ELSE LEFT( @path, @slashPos ) END )

END
GO
CREATE FUNCTION [dbo].[getFileNameFromPath](
	@path NVARCHAR(256)
)
RETURNS SYSNAME
AS
BEGIN

	DECLARE @slashPos	INT		= CASE WHEN CHARINDEX( '\', REVERSE(@path) ) > 0 THEN CHARINDEX( '\', REVERSE(@path) ) -1 ELSE LEN(@path) END
	RETURN RIGHT( @path, @slashPos ) 
END
GO
-- =============================================
-- END of Dependencies
-- =============================================
DECLARE	@dbname		SYSNAME = NULL
		, @fileType	SYSNAME = NULL

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#dbs')			IS NOT NULL DROP TABLE #dbs

IF OBJECT_ID('tempdb..#filesUsage')		IS NOT NULL DROP TABLE #filesUsage

IF OBJECT_ID('tempdb..#volume_stats')	IS NOT NULL DROP TABLE #volume_stats

-- Databases we will loop through
CREATE TABLE #dbs (
	ID					INT IDENTITY(1,1)
	, database_id		INT
	, database_name		SYSNAME)

-- To hold the results of files usage
CREATE TABLE #filesUsage (
	database_id				INT
	, [file_id]				INT
	, [logical_name]		SYSNAME
	, [data_space_id]		INT
	, [type_desc]			SYSNAME
	, [filegroup]			SYSNAME		NULL
	, [is_FG_readonly]		VARCHAR(3)	NULL
	, [max_size]			INT
	, [growth]				INT
	, [is_percent_growth]	BIT
	, [physical_name]		NVARCHAR(512)
	, [size]				BIGINT
	, [spaceUsed]			BIGINT		NULL)

DECLARE @db				SYSNAME = NULL
		, @countDBs		INT = 1
		, @numDBs		INT
		, @sqlstring	NVARCHAR(4000)

IF ISNULL(@fileType, '') NOT IN ('ROWS', 'LOG', 'FILESTREAM', 'FULLTEXT', '') BEGIN
	RAISERROR ('The parameter @fileType accepts only one of the following values: ROWS, LOG, FILESTREAM, FULLTEXT or NULL', 16, 0 ,0)
	GOTO OnError
END

-- Get volume statistics
-- Get one pair database-file per Drive
;WITH cte AS(
	SELECT tempdb.dbo.getDriveFromFullPath(physical_name) AS Drive
			, MIN(database_id) AS database_id
			, (SELECT MIN(file_id) AS file_id
					FROM master.sys.master_files 
					WHERE database_id = MIN(mf.database_id) 
						AND tempdb.dbo.getDriveFromFullPath(physical_name) = tempdb.dbo.getDriveFromFullPath(mf.physical_name)) AS file_id
		FROM master.sys.master_files AS mf
		GROUP BY tempdb.dbo.getDriveFromFullPath(physical_name)
)

SELECT SERVERPROPERTY('MachineName') AS ServerName
		, vs.volume_mount_point AS Drive
		, vs.logical_volume_name AS VolName
		, vs.file_system_type AS FileSystem
		, vs.total_bytes / 1024 / 1024 AS SizeMB
		, vs.available_bytes / 1024 / 1024 AS FreeMB
	INTO #volume_stats
	FROM cte 
		CROSS APPLY master.sys.dm_os_volume_stats (cte.database_id, file_id) AS vs

-- Get files info from sys.master_files to get also from databases not ONLINE
INSERT INTO #filesUsage (database_id
						, [file_id]	
						, [logical_name]
						, [data_space_id]
						, [type_desc]
						, [max_size]
						, [growth]
						, [is_percent_growth]
						, [physical_name]
						, [size])
	SELECT f.database_id
		, f.file_id
		, f.name AS logical_name
		, f.data_space_id
		, f.type_desc 
		, f.max_size
		, f.growth
		, f.is_percent_growth
		, f.physical_name
		, f.size
	FROM sys.master_files AS f

INSERT INTO #dbs (database_id, database_name)
	SELECT database_id
			, name 
		FROM sys.databases
		WHERE state = 0 
			AND source_database_id IS NULL
			AND @dbname IS NULL
	UNION ALL 
	SELECT database_id
			, name 
		FROM sys.databases 
		WHERE state = 0 
			AND name LIKE @dbname
		ORDER BY name			

SET @numDBs = @@ROWCOUNT

WHILE @countDBs <= @numDBs BEGIN

	SELECT @db = database_name 
		FROM #dbs 
		WHERE ID = @countDBs

	SET @sqlstring	= N'
		USE ' + QUOTENAME(@db) + N'

		UPDATE f	
			SET f.[filegroup] = ISNULL(sp.name, ''Not Applicable'')
				, f.[is_FG_readonly] = CASE WHEN FILEGROUPPROPERTY ( sp.name , ''IsReadOnly'' ) = 1 THEN ''YES'' ELSE ''NO'' END
				, f.[spaceUsed] = CONVERT(BIGINT, FILEPROPERTY(f.logical_name, ''SpaceUsed'')) 
				, f.[size] = dbf.[size]
			FROM #filesUsage AS f
				LEFT JOIN sys.data_spaces AS sp
					ON sp.data_space_id = f.data_space_id
				LEFT JOIN sys.database_files AS dbf
					ON dbf.file_id = f.file_id
						AND f.database_id = DB_ID()
			WHERE database_id = DB_ID()									
	'
	BEGIN TRY
		EXEC sp_executesql @sqlstring
	END TRY
	BEGIN CATCH
	END CATCH
	
	SET @countDBs = @countDBs + 1
END


SELECT @@SERVERNAME AS [Server Name]
		, r.database_name
		, r.Path as Rows_Path
		, l.Path AS Log_Path 
		, CASE WHEN [dbo].[getDriveFromFullPath] (r.Path) = [dbo].[getDriveFromFullPath] (l.Path) THEN 'Same Drive' ELSE 'Different Drive' END AS Drive_Status 
		, CASE WHEN r.Path = l.Path THEN 'Same Path' ELSE 'Different Path' END AS Path_Status
		, CASE WHEN 
			[dbo].[getDriveFromFullPath] (r.Path) = [dbo].[getDriveFromFullPath] (l.Path) 
			OR r.Path = l.Path THEN 'Yes' ELSE 'No' 
		END AS Needs_review

	FROM (

			SELECT	DB_NAME(f.database_id) AS database_name
					, f.type_desc
					, REPLACE (f.physical_name, [tempdb].[dbo].[getFileNameFromPath](f.physical_name), '') AS [Path]
				FROM #filesUsage AS f
					INNER JOIN sys.databases AS d
						ON d.database_id = f.database_id
					LEFT JOIN #volume_stats AS vs
						ON tempdb.dbo.getDriveFromFullPath(vs.Drive) = tempdb.dbo.getDriveFromFullPath(f.physical_name)
				WHERE f.type_desc = ISNULL('ROWS', f.type_desc)
					AND source_database_id IS NULL
					AND d.name LIKE ISNULL(@dbname, d.name)
				GROUP BY f.database_id
						, f.type_desc
						, REPLACE (f.physical_name, [tempdb].[dbo].[getFileNameFromPath](f.physical_name), '')
			) AS r
		INNER JOIN 
			(

			SELECT	DB_NAME(f.database_id) AS database_name
					, f.type_desc
					, REPLACE (f.physical_name, [tempdb].[dbo].[getFileNameFromPath](f.physical_name), '') AS [Path]
				FROM #filesUsage AS f
					INNER JOIN sys.databases AS d
						ON d.database_id = f.database_id
					LEFT JOIN #volume_stats AS vs
						ON tempdb.dbo.getDriveFromFullPath(vs.Drive) = tempdb.dbo.getDriveFromFullPath(f.physical_name)
				WHERE f.type_desc = ISNULL('LOG', f.type_desc)
					AND source_database_id IS NULL
					AND d.name LIKE ISNULL(@dbname, d.name)
				GROUP BY f.database_id
						, f.type_desc
						, REPLACE (f.physical_name, [tempdb].[dbo].[getFileNameFromPath](f.physical_name), '')
			) AS l
		ON l.database_name = r.database_name
	WHERE r.database_name NOT IN ('master', 'model', 'msdb', 'SSISDB')

	ORDER BY database_name			

IF OBJECT_ID('tempdb..#dbs')			IS NOT NULL DROP TABLE #dbs

IF OBJECT_ID('tempdb..#filesUsage')		IS NOT NULL DROP TABLE #filesUsage

IF OBJECT_ID('tempdb..#volume_stats')	IS NOT NULL DROP TABLE #volume_stats
OnError:
GO
-- =============================================
-- Dependencies:This Section will remove any dependancy
-- =============================================
USE tempdb
GO
DROP FUNCTION [dbo].[getDriveFromFullPath]
GO
DROP FUNCTION [dbo].[getFileNameFromPath]
GO
