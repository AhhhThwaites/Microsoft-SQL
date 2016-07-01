/*
    File: Block Killer.sql
    Desc: For the server, kill all blocking sessions. Emergencies only.
	Date: 01/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  01/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @intKill INT
   ,@varDatabase VARCHAR(50)
   ,@varSQL VARCHAR(1000)
   ,@varDrop VARCHAR(100);
	
SELECT  @intKill = blocking_session_id
FROM    sys.dm_exec_requests
WHERE   session_id NOT LIKE @@SPID
        AND session_id >= 50
        AND blocking_session_id > 0;

IF @intKill IS NOT NULL
    BEGIN
        PRINT '***KILLING SESSIONS***';
        WHILE @intKill IS NOT NULL
            BEGIN
                SELECT  @varSQL = 'KILL ' + CAST(@intKill AS VARCHAR);
                PRINT @varSQL;
                EXEC (@varSQL);
					
                SELECT  @intKill = NULL;

                SELECT  @intKill = blocking_session_id
                FROM    sys.dm_exec_requests
                WHERE   session_id NOT LIKE @@SPID
                        AND session_id >= 50
                        AND blocking_session_id > 0;
            END;
    END;
ELSE
    PRINT 'nothing to KILL ';
