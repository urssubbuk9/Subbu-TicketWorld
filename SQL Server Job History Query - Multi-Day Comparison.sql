/* 
Author: Subbu CN
Description: Queries job history to find which jobs would have been running at a certain time
             ENHANCEMENT: Compares last 3 days of job executions and identifies jobs that didn't run every day

Changes : 
    RAG - 2019-03-18 - Changed the duration to be calculated in seconds and then added to '2010-01-01' to avoid errors when a job
                       run for longer than 24h
                     - Added run_duration which will be in this format [d.hh:mm:ss]
    RAG - 2019-04-26 - Changed a concrete time for a time range to give more flexibility.
    RAG - 2019-04-29 - Changed how duration was calculated to make it simpler
    Enhanced - 2024  - Added multi-day comparison and missing job execution detection
*/

-- =============================================
-- Dependencies: This Section will create on tempdb any dependency
-- =============================================
USE tempdb
GO

IF OBJECT_ID('tempdb.dbo.formatMStimeToHR') IS NOT NULL
    DROP FUNCTION [dbo].[formatMStimeToHR]
GO

CREATE FUNCTION [dbo].[formatMStimeToHR](
    @duration INT
)
RETURNS VARCHAR(24)
AS
BEGIN
    DECLARE @strDuration VARCHAR(24)
    DECLARE @R VARCHAR(24)

    SET @strDuration = RIGHT(REPLICATE('0',24) + CONVERT(VARCHAR(24),@duration), 24)

    SET @R = ISNULL(NULLIF(CONVERT(VARCHAR, CONVERT(INT,SUBSTRING(@strDuration, 1, 20)) / 24 ),0) + '.', '') + 
                RIGHT('00' + CONVERT(VARCHAR, CONVERT(INT,SUBSTRING(@strDuration, 1, 20)) % 24 ), 2) + ':' + 
                SUBSTRING(@strDuration, 21, 2) + ':' + 
                SUBSTRING(@strDuration, 23, 2)
    
    RETURN ISNULL(@R,'-')
END
GO

-- =============================================
-- CONFIGURATION SECTION
-- =============================================

DECLARE @targetTimeFrom DATETIME    SET @targetTimeFrom = '2019-04-25 06:00:00';
DECLARE @targetTimeTo DATETIME      SET @targetTimeTo = ISNULL('2019-04-25 07:00:00', @targetTimeFrom);
DECLARE @daysToCompare INT          SET @daysToCompare = 3; -- Compare last N days

-- =============================================
-- PART 1: ORIGINAL QUERY - Jobs Running in Time Range
-- =============================================

PRINT '========================================='
PRINT 'PART 1: Jobs Running During Target Time'
PRINT '========================================='
PRINT 'Time Range: ' + CONVERT(VARCHAR(20), @targetTimeFrom, 120) + ' to ' + CONVERT(VARCHAR(20), @targetTimeTo, 120)
PRINT ''

DECLARE @filter INT = CAST(CONVERT(CHAR(8), @targetTimeFrom, 112) AS INT);

;WITH times AS
(
    SELECT
        job_id,
        step_name,
        run_date,
        -- Start DATE and TIME combined
        LEFT(run_date, 4) + '-' + SUBSTRING(CAST(run_date AS CHAR(8)),5,2) + '-' + RIGHT(run_date,2) + ' ' + 
        LEFT(REPLICATE('0', 6 - LEN(run_time)) + CAST(run_time AS VARCHAR(6)), 2) + ':' + 
        SUBSTRING(REPLICATE('0', 6 - LEN(run_time)) + CAST(run_time AS VARCHAR(6)), 3, 2) + ':' 
        + RIGHT(REPLICATE('0', 6 - LEN(run_time)) + CAST(run_time AS VARCHAR(6)), 2) AS [start_time],
        
        -- Duration calculation
        DATEADD(SECOND, 
            (LEFT(RIGHT('000000' + CONVERT(VARCHAR, run_duration), 6), 2) * 3600 
                + LEFT(RIGHT('000000' + CONVERT(VARCHAR, run_duration), 4), 2) * 60
                + RIGHT('000000' + CONVERT(VARCHAR, run_duration), 2))
            , '2010-01-01'
        ) AS [duration],
        run_duration,
        run_status,
        message
    FROM
        msdb.dbo.sysjobhistory
    WHERE
        run_date IN (@filter - 1, @filter, @filter + 1)
        AND step_id = 0  -- 0 = Overall job outcome
)

SELECT
    j.name AS job_name,
    t.start_time,
    DATEADD(ss, DATEDIFF(ss, '2010-01-01 00:00:00', duration), start_time) AS end_time,
    [tempdb].[dbo].[formatMStimeToHR](run_duration) AS run_duration,
    CASE t.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS status
FROM
    times t
    INNER JOIN msdb.dbo.sysjobs j ON j.job_id = t.job_id
WHERE 
    start_time < @targetTimeTo
    AND DATEADD(ss, DATEDIFF(ss, '2010-01-01 00:00:00', duration), start_time) > @targetTimeFrom
ORDER BY 
    start_time, j.name

-- =============================================
-- PART 2: MULTI-DAY COMPARISON - Last N Days
-- =============================================

PRINT ''
PRINT '========================================='
PRINT 'PART 2: Job Execution Summary - Last ' + CAST(@daysToCompare AS VARCHAR) + ' Days'
PRINT '========================================='
PRINT ''

DECLARE @startDate DATE = CAST(DATEADD(DAY, -(@daysToCompare - 1), GETDATE()) AS DATE);
DECLARE @endDate DATE = CAST(GETDATE() AS DATE);

PRINT 'Analysis Period: ' + CONVERT(VARCHAR(10), @startDate, 120) + ' to ' + CONVERT(VARCHAR(10), @endDate, 120)
PRINT ''

-- Create date range for comparison
;WITH DateRange AS (
    SELECT @startDate AS CompareDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CompareDate)
    FROM DateRange
    WHERE CompareDate < @endDate
),
-- Get all job executions for the period
JobExecutions AS (
    SELECT 
        j.job_id,
        j.name AS job_name,
        j.enabled,
        CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE) AS execution_date,
        h.run_status,
        h.run_duration,
        LEFT(REPLICATE('0', 6 - LEN(h.run_time)) + CAST(h.run_time AS VARCHAR(6)), 2) + ':' + 
        SUBSTRING(REPLICATE('0', 6 - LEN(h.run_time)) + CAST(h.run_time AS VARCHAR(6)), 3, 2) + ':' 
        + RIGHT(REPLICATE('0', 6 - LEN(h.run_time)) + CAST(h.run_time AS VARCHAR(6)), 2) AS execution_time,
        ROW_NUMBER() OVER (PARTITION BY j.job_id, CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE) 
                          ORDER BY h.run_date DESC, h.run_time DESC) AS rn
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
    WHERE h.step_id = 0  -- Overall job outcome only
        AND h.run_date >= CAST(CONVERT(CHAR(8), @startDate, 112) AS INT)
        AND h.run_date <= CAST(CONVERT(CHAR(8), @endDate, 112) AS INT)
),
-- Aggregate by job and date
JobSummary AS (
    SELECT
        job_id,
        job_name,
        enabled,
        execution_date,
        MAX(CASE WHEN run_status = 1 THEN 1 ELSE 0 END) AS succeeded,
        MAX(CASE WHEN run_status = 0 THEN 1 ELSE 0 END) AS failed,
        COUNT(*) AS execution_count,
        MAX(execution_time) AS last_execution_time,
        MAX([tempdb].[dbo].[formatMStimeToHR](run_duration)) AS max_duration
    FROM JobExecutions
    WHERE rn = 1  -- Most recent execution per day
    GROUP BY job_id, job_name, enabled, execution_date
)

-- Final comparison across all dates
SELECT
    js.job_name,
    js.enabled,
    COUNT(DISTINCT js.execution_date) AS days_executed,
    @daysToCompare AS days_in_period,
    CASE 
        WHEN COUNT(DISTINCT js.execution_date) = @daysToCompare THEN 'Ran Every Day'
        WHEN COUNT(DISTINCT js.execution_date) = 0 THEN 'Never Ran'
        ELSE 'INCONSISTENT - Missing ' + CAST(@daysToCompare - COUNT(DISTINCT js.execution_date) AS VARCHAR) + ' day(s)'
    END AS execution_pattern,
    SUM(succeeded) AS total_successes,
    SUM(failed) AS total_failures,
    SUM(execution_count) AS total_executions,
    -- Show which specific days it ran
    STUFF((
        SELECT ', ' + CONVERT(VARCHAR(10), execution_date, 120)
        FROM JobSummary js2
        WHERE js2.job_id = js.job_id
        ORDER BY execution_date
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS dates_executed
FROM JobSummary js
GROUP BY js.job_id, js.job_name, js.enabled
ORDER BY 
    CASE 
        WHEN COUNT(DISTINCT js.execution_date) = @daysToCompare THEN 1
        WHEN COUNT(DISTINCT js.execution_date) = 0 THEN 3
        ELSE 2
    END,
    js.job_name

-- =============================================
-- PART 3: JOBS THAT DID NOT RUN EVERY DAY
-- =============================================

PRINT ''
PRINT '========================================='
PRINT 'PART 3: Jobs with Inconsistent Execution'
PRINT '========================================='
PRINT ''

;WITH DateRange AS (
    SELECT @startDate AS CompareDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CompareDate)
    FROM DateRange
    WHERE CompareDate < @endDate
),
JobExecutions AS (
    SELECT 
        j.job_id,
        j.name AS job_name,
        j.enabled,
        CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE) AS execution_date,
        h.run_status
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
    WHERE h.step_id = 0
        AND h.run_date >= CAST(CONVERT(CHAR(8), @startDate, 112) AS INT)
        AND h.run_date <= CAST(CONVERT(CHAR(8), @endDate, 112) AS INT)
),
JobDaySummary AS (
    SELECT
        job_id,
        job_name,
        enabled,
        execution_date
    FROM JobExecutions
    GROUP BY job_id, job_name, enabled, execution_date
),
AllJobsAllDates AS (
    SELECT 
        j.job_id,
        j.name AS job_name,
        j.enabled,
        dr.CompareDate
    FROM msdb.dbo.sysjobs j
    CROSS JOIN DateRange dr
    WHERE j.enabled = 1  -- Only check enabled jobs
)

SELECT
    ajad.job_name,
    ajad.CompareDate AS missing_date,
    DATENAME(WEEKDAY, ajad.CompareDate) AS day_of_week,
    CASE 
        WHEN ajad.enabled = 0 THEN 'Job Disabled'
        ELSE 'Did Not Execute'
    END AS reason
FROM AllJobsAllDates ajad
LEFT JOIN JobDaySummary jds 
    ON ajad.job_id = jds.job_id 
    AND ajad.CompareDate = jds.execution_date
WHERE jds.execution_date IS NULL  -- No execution found
    AND ajad.enabled = 1  -- Only show enabled jobs
ORDER BY ajad.job_name, ajad.CompareDate

-- =============================================
-- PART 4: DETAILED DAY-BY-DAY BREAKDOWN
-- =============================================

PRINT ''
PRINT '========================================='
PRINT 'PART 4: Detailed Day-by-Day Execution Matrix'
PRINT '========================================='
PRINT ''

;WITH DateRange AS (
    SELECT @startDate AS CompareDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CompareDate)
    FROM DateRange
    WHERE CompareDate < @endDate
),
JobExecutions AS (
    SELECT 
        j.job_id,
        j.name AS job_name,
        CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE) AS execution_date,
        h.run_status,
        ROW_NUMBER() OVER (PARTITION BY j.job_id, 
                          CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE)
                          ORDER BY h.run_date DESC, h.run_time DESC) AS rn
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
    WHERE h.step_id = 0
        AND h.run_date >= CAST(CONVERT(CHAR(8), @startDate, 112) AS INT)
        AND h.run_date <= CAST(CONVERT(CHAR(8), @endDate, 112) AS INT)
        AND j.enabled = 1
)

-- Dynamic pivot for last N days
SELECT
    job_name,
    [Day1] = MAX(CASE WHEN CompareDate = DATEADD(DAY, 0, @startDate) THEN status_icon END),
    [Day1_Date] = CONVERT(VARCHAR(10), DATEADD(DAY, 0, @startDate), 120),
    [Day2] = MAX(CASE WHEN CompareDate = DATEADD(DAY, 1, @startDate) THEN status_icon END),
    [Day2_Date] = CONVERT(VARCHAR(10), DATEADD(DAY, 1, @startDate), 120),
    [Day3] = MAX(CASE WHEN CompareDate = DATEADD(DAY, 2, @startDate) THEN status_icon END),
    [Day3_Date] = CONVERT(VARCHAR(10), DATEADD(DAY, 2, @startDate), 120),
    consistency_score = CAST(
        (SUM(CASE WHEN status_icon IN ('✓', '✗') THEN 1 ELSE 0 END) * 100.0 / @daysToCompare) 
        AS DECIMAL(5,2))
FROM (
    SELECT 
        j.name AS job_name,
        dr.CompareDate,
        CASE 
            WHEN je.run_status = 1 THEN '✓ Success'
            WHEN je.run_status = 0 THEN '✗ Failed'
            WHEN je.run_status IS NULL THEN '- No Run'
            ELSE '? Unknown'
        END AS status_icon
    FROM msdb.dbo.sysjobs j
    CROSS JOIN DateRange dr
    LEFT JOIN JobExecutions je 
        ON j.job_id = je.job_id 
        AND dr.CompareDate = je.execution_date
        AND je.rn = 1
    WHERE j.enabled = 1
) AS SourceData
GROUP BY job_name
ORDER BY consistency_score, job_name

-- =============================================
-- PART 5: SCHEDULE ANALYSIS
-- =============================================

PRINT ''
PRINT '========================================='
PRINT 'PART 5: Job Schedule vs Actual Execution'
PRINT '========================================='
PRINT ''

SELECT 
    j.name AS job_name,
    j.enabled AS job_enabled,
    s.name AS schedule_name,
    CASE s.freq_type
        WHEN 1 THEN 'Once'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly relative'
        WHEN 64 THEN 'When SQL Server Agent starts'
        WHEN 128 THEN 'Start whenever CPUs idle'
        ELSE 'Unknown'
    END AS schedule_frequency,
    s.enabled AS schedule_enabled,
    -- Count actual executions in last N days
    (SELECT COUNT(DISTINCT CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE))
     FROM msdb.dbo.sysjobhistory h
     WHERE h.job_id = j.job_id
       AND h.step_id = 0
       AND h.run_date >= CAST(CONVERT(CHAR(8), @startDate, 112) AS INT)
       AND h.run_date <= CAST(CONVERT(CHAR(8), @endDate, 112) AS INT)
    ) AS actual_execution_days,
    @daysToCompare AS expected_days_if_daily,
    CASE 
        WHEN s.freq_type = 4 AND j.enabled = 1 AND s.enabled = 1 THEN 'Should run daily'
        WHEN s.freq_type = 8 AND j.enabled = 1 AND s.enabled = 1 THEN 'Should run weekly'
        WHEN j.enabled = 0 THEN 'Job disabled'
        WHEN s.enabled = 0 THEN 'Schedule disabled'
        ELSE 'Check schedule'
    END AS expectation
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
ORDER BY j.name, s.name

-- =============================================
-- PART 6: SUMMARY STATISTICS
-- =============================================

PRINT ''
PRINT '========================================='
PRINT 'PART 6: Summary Statistics'
PRINT '========================================='
PRINT ''

DECLARE @totalJobs INT
DECLARE @enabledJobs INT
DECLARE @jobsRanEveryDay INT
DECLARE @jobsNeverRan INT
DECLARE @jobsInconsistent INT

SELECT 
    @totalJobs = COUNT(DISTINCT j.job_id),
    @enabledJobs = COUNT(DISTINCT CASE WHEN j.enabled = 1 THEN j.job_id END)
FROM msdb.dbo.sysjobs j

;WITH DateRange AS (
    SELECT @startDate AS CompareDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CompareDate)
    FROM DateRange
    WHERE CompareDate < @endDate
),
JobExecutions AS (
    SELECT 
        j.job_id,
        CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE) AS execution_date
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
    WHERE h.step_id = 0
        AND h.run_date >= CAST(CONVERT(CHAR(8), @startDate, 112) AS INT)
        AND h.run_date <= CAST(CONVERT(CHAR(8), @endDate, 112) AS INT)
        AND j.enabled = 1
    GROUP BY j.job_id, CAST(LEFT(h.run_date, 4) + '-' + SUBSTRING(CAST(h.run_date AS CHAR(8)),5,2) + '-' + RIGHT(h.run_date,2) AS DATE)
)

SELECT
    @jobsRanEveryDay = COUNT(DISTINCT CASE WHEN day_count = @daysToCompare THEN job_id END),
    @jobsNeverRan = @enabledJobs - COUNT(DISTINCT job_id),
    @jobsInconsistent = COUNT(DISTINCT CASE WHEN day_count > 0 AND day_count < @daysToCompare THEN job_id END)
FROM (
    SELECT job_id, COUNT(DISTINCT execution_date) AS day_count
    FROM JobExecutions
    GROUP BY job_id
) AS JobDayCounts

SELECT 
    'Summary Statistics' AS report_section,
    @totalJobs AS total_jobs,
    @enabledJobs AS enabled_jobs,
    @jobsRanEveryDay AS jobs_ran_every_day,
    @jobsInconsistent AS jobs_with_missing_days,
    @jobsNeverRan AS jobs_never_ran,
    CAST((@jobsRanEveryDay * 100.0 / NULLIF(@enabledJobs, 0)) AS DECIMAL(5,2)) AS pct_consistent_execution

-- =============================================
-- Cleanup: Remove dependencies
-- =============================================
PRINT ''
PRINT '========================================='
PRINT 'Cleanup Complete'
PRINT '========================================='

USE tempdb
GO
DROP FUNCTION IF EXISTS [dbo].[formatMStimeToHR]
GO
