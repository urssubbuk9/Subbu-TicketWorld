-- =============================================
-- Author:      Raul Gonzalez
-- Create date: dd/MM/yyyy
-- Description: Returns max memory recommendation based on the memory present in the server.
--              This process will not considered
--              - Other instances present on the server
--              - SQL Server edition constraints (eg. Standard Edition cap)
--
--              The command to change the configurato
-- Change Log:
--				2019-08-05	RAG	- Execute total memory query based on SQL Server version
-- 								- Script now to have SQLCMD systax for running this script in multi server connections.
--
-- Remarks: Calculations based on this blog post
--          https://www.sqlskills.com/blogs/jonathan/wow-an-online-calculator-to-misconfigure-your-sql-server-memory/
-- 
-- =============================================
DECLARE @TotalVisibleMemorySizeGB	INT 
DECLARE @TotalVisibleMemorySizeMB	INT
DECLARE @MaxServerMemory			INT
DECLARE @CurrentMaxServerMemoryMB	INT = (SELECT CEILING(CONVERT(INT, value_in_use)) FROM sys.configurations WHERE name = 'max server memory (MB)')
DECLARE @MajorVersion				TINYINT;
DECLARE @sql NVARCHAR(MAX)

SET @MajorVersion = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))-1);

IF @MajorVersion < 11 BEGIN
	SET @sql = N'SELECT @TotalVisibleMemorySizeGB = CEILING(physical_memory_in_bytes / 1024. / 1024 / 1024) FROM sys.dm_os_sys_info'
END
ELSE BEGIN
	SET @sql = N'SELECT @TotalVisibleMemorySizeGB = CEILING(physical_memory_kb / 1024. / 1024) FROM sys.dm_os_sys_info'
END

EXECUTE sys.sp_executesql 
	@Stmt = @sql
	, @Params = N'@TotalVisibleMemorySizeGB INT OUTPUT'
	, @TotalVisibleMemorySizeGB = @TotalVisibleMemorySizeGB OUTPUT --(SELECT CEILING(physical_memory_kb / 1024. / 1024) FROM sys.dm_os_sys_info)

-- 1GB + 1GB per each 4GB between 4GB and 16GB + 1GB for each 8GB between 16GB and 256GB + 1GB for each 16GB between 256GB and infinite
SELECT 
		@MaxServerMemory = (
		@TotalVisibleMemorySizeGB - 
		CASE 
			WHEN @TotalVisibleMemorySizeGB < 4					THEN 1
			WHEN @TotalVisibleMemorySizeGB BETWEEN 4 AND 16		THEN 1 + ((@TotalVisibleMemorySizeGB - 4) / 4)
			WHEN @TotalVisibleMemorySizeGB BETWEEN 17 AND 256	THEN 1 + ((16 - 4) / 4) + ((@TotalVisibleMemorySizeGB - 16) / 8)
			WHEN @TotalVisibleMemorySizeGB > 257				THEN 1 + ((16 - 4) / 4) + ((256 - 16) / 8) + ((@TotalVisibleMemorySizeGB - 256) / 16)
		END
		) * 1024
SELECT @TotalVisibleMemorySizeGB AS TotalVisibleMemorySizeGB
		, @MaxServerMemory AS MaxMemoryMB
		, @MaxServerMemory / 1024 AS MaxMemoryGB
		, @CurrentMaxServerMemoryMB AS CurrentMaxServerMemoryMB
		, ':CONNECT ' + @@SERVERNAME + CHAR(10) 
			+ 'EXECUTE sp_configure ''max server memory (MB)'', ' + CONVERT(VARCHAR, @MaxServerMemory) + CHAR(10) + 'RECONFIGURE;' + CHAR(10) + 'GO' AS [sp_configure];
GO
