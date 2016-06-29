/*
    File: Estimate Restore Completion.sql
    Desc: ESTIMATED query completion for backup/restore/shrink
    Date: 29/06/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  29/06/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  DB_NAME(database_id) AS DBName
       ,der.session_id
       ,der.command
       ,der.status
       ,der.percent_complete
       ,der.estimated_completion_time
       ,CONVERT(VARCHAR(10), DATEADD(ms, der.estimated_completion_time, 0), 8) EstimatedTimeLeft
FROM    sys.dm_exec_requests AS der WITH (NOLOCK)
WHERE   command = 'restore database'
        OR command = 'backup database'
        OR command = 'restore log'
        OR command = 'DbccFilesCompact'
        OR command = 'Alter Index'
        OR command = 'Alter Table'
        OR command = 'BACKUP LOG'
        OR command = 'DB STARTUP';


