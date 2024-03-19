-- ==========================
-- Correct Auto-grow settings
-- ==========================
SELECT 'ALTER DATABASE [' + DB_NAME() + '] MODIFY FILE (NAME = N''' + name + ''', FILEGROWTH = ' + 
    CASE 
        WHEN ((size * 8) / 1024) < 500 THEN '100MB)' 
        WHEN ((size * 8) / 1024) BETWEEN 501 AND 1000 THEN '200MB)' 
        WHEN ((size * 8) / 1024) BETWEEN 1001 AND 2000 THEN '500MB)' 
        WHEN ((size * 8) / 1024) BETWEEN 2001 AND 5000 THEN '1000MB)' 
        WHEN ((size * 8) / 1024) BETWEEN 5001 AND 20000 THEN '2000MB)' 
        ELSE '2000MB)'
        END + '; ' AS [Autogrow T-SQL]
FROM sys.master_files
WHERE database_id = DB_ID()
AND (
        (
            is_percent_growth = 0 
            and growth > 0 
            and 
            (
                growth * 8 / 1024 < 100
                or (size * 8 / 1024  between 501 and 1000 and  growth * 8 / 1024 < 200)
                or (size * 8 / 1024  between 1001 and 2000 and  growth * 8 / 1024 < 500)
                or (size * 8 / 1024  between 2001 and 5000 and  growth * 8 / 1024 < 1000)
                or (size * 8 / 1024  > 5001 and   growth * 8 / 1024 < 2000)
            )
        )
        or is_percent_growth = 1
    )
ORDER BY [file_id];
