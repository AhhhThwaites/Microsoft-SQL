/*
    File: Backup LOG to NUL.sql
    Desc: Backups up the LOG where a log is required, TO NUL writes a file locally and discards it.
    Date: 21/01/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/01/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN
    DECLARE @intMinLoop INT
       ,@intMaxLoop INT
       ,@varSQL VARCHAR(500);

    SELECT  @intMinLoop = MIN(database_id)
           ,@intMaxLoop = MAX(database_id)
    FROM    sys.databases
    WHERE   database_id > 4
            AND name NOT IN ( 'ReportServer','ReportServerTempDB' )
            AND recovery_model_desc = 'FULL'
            AND state_desc = 'ONLINE'
            AND log_reuse_wait_desc = 'LOG_BACKUP';

    WHILE @intMinLoop <= @intMaxLoop
        BEGIN
            SELECT  @varSQL = 'BACKUP LOG [' + DB_NAME(@intMinLoop) + '] TO DISK = N''NUL''' + CHAR(13);

            BEGIN TRY
                PRINT ( @varSQL );
                EXEC	(@varSQL);
            END TRY
            BEGIN CATCH
                PRINT CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
            END CATCH;

            SELECT  @intMinLoop = MIN(database_id)
            FROM    sys.databases
            WHERE   database_id > 4
                    AND name NOT IN ( 'ReportServer','ReportServerTempDB' )
                    AND recovery_model_desc = 'FULL'
                    AND state_desc = 'ONLINE'
                    AND log_reuse_wait_desc = 'LOG_BACKUP'
                    AND database_id > @intMinLoop;
        END;
END;