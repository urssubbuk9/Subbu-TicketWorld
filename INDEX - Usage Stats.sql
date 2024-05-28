-- ============================
-- Author: Subbu CN
-- Title:  Show index usage
-- Source: Joe's Internals & Troubleshooting Workshop
-- ============================

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SELECT
    o.name AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    (s.user_seeks + s.user_scans + s.user_lookups) AS UserReads,
    s.user_updates,
    s.system_seeks,
    s.system_scans,
    s.system_lookups,
    (s.system_seeks + s.system_scans + s.system_lookups) AS SystemReads,
    s.system_updates,
    (SELECT SUM(p.rows)
    FROM sys.partitions p
    WHERE p.index_id = i.index_id AND p.object_id = i.object_id) AS Rows,
    CAST((CASE
		WHEN s.user_updates < 1 THEN -1
		ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
		END) AS bigint) AS ReadsPerWrite,
    (SELECT DATEDIFF(DAY, create_date, CURRENT_TIMESTAMP)
    FROM sys.databases
    WHERE name = 'tempdb') AS ServerUptimeDays
FROM sys.objects AS o
    JOIN sys.indexes AS i
    ON o.object_id = i.object_id
    JOIN sys.schemas AS c
    ON o.schema_id = c.schema_id
    LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s
    ON i.index_id = s.index_id
        AND i.object_id = s.object_id
        AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(o.object_id,'IsUserTable') = 1
    --AND i.type_desc = 'nonclustered'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
--AND (SELECT SUM(p.rows) FROM sys.partitions AS p WHERE p.index_id = i.index_id AND p.object_id = i.object_id) > 1000
ORDER BY ReadsPerWrite DESC;
