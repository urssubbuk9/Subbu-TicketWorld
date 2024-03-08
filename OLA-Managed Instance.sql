SELECT DatabaseName + '.' + SchemaName + '.' + ObjectName AS ObjectName,
    IndexName,
    CASE IndexType WHEN 1 THEN 'CLUSTERED' WHEN 2 THEN 'NONCLUSTERED' WHEN 3 THEN 'XML' WHEN 4 THEN 'SPATIAL' END AS IndexType,
    CASE WHEN Command LIKE '%REBUILD%' THEN 'REBUILD' WHEN Command LIKE '%REORGANIZE%' THEN 'REORGANIZE' END AS Action,
    StartTime,
    EndTime,
    --STUFF(CONVERT(char(8), EndTime - StartTime, 108), 1, 2, DATEDIFF(hh, 0, EndTime - StartTime)) AS Duration,
    ExtendedInfo.value('(ExtendedInfo/Fragmentation)[1]','float') AS Fragmentation,
    CASE WHEN ObjectType = 'U' THEN 'USER_TABLE' WHEN ObjectType = 'V' THEN 'VIEW' END AS ObjectType,
    ExtendedInfo.value('(ExtendedInfo/PageCount)[1]','int') AS [PageCount],
    CONVERT(decimal(10, 2), ExtendedInfo.value('(ExtendedInfo/PageCount)[1]','bigint') * 8 / 1024.0) AS SizeMB,
    PartitionNumber,
    Command,
    ErrorNumber,
    ErrorMessage
FROM dbo.CommandLog
WHERE CommandType = 'ALTER_INDEX'--UPDATE_STATISTICS
    AND StartTime >= DATEADD(dd, -7, GETDATE())
ORDER BY StartTime DESC;
