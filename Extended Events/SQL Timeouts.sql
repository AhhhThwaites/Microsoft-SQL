/*
    File: SQL Timeouts.sql
    Desc: Extended event sessions to capture RPC or SQLSTMT timeouts (Abort)
    Date: 25/01/2015
    
    Version Change          Date        Notes
    1.0     Initial Commit  25/01/2016  none
*/

IF EXISTS ( SELECT  *
            FROM    sys.dm_xe_sessions
            WHERE   name = 'TS:Timeouts' )
    BEGIN
        DROP EVENT SESSION [TS:Timeouts] ON SERVER; 
    END;
GO

--Create XE session
IF NOT EXISTS ( SELECT  *
                FROM    sys.dm_xe_sessions
                WHERE   name = 'TS:Timeouts' )
    BEGIN
        CREATE EVENT SESSION [TS:Timeouts] ON SERVER
        ADD EVENT sqlserver.sql_batch_completed (  SET collect_batch_text = ( 1 )
            ACTION ( sqlserver.session_id,sqlserver.username )
            WHERE ( [package0].[equal_uint64]([result],( 2 )) ) )
        ADD TARGET package0.pair_matching (  SET begin_event = N'sqlserver.sql_batch_starting'
                                            ,begin_matching_actions = N'sqlserver.session_id'
                                            ,begin_matching_columns = N'batch_text'
                                            ,end_event = N'sqlserver.sql_batch_completed'
                                            ,end_matching_actions = N'sqlserver.session_id'
                                            ,end_matching_columns = N'batch_text' )
        WITH (  MAX_MEMORY = 4096 KB
               ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
               ,MAX_DISPATCH_LATENCY = 30 SECONDS
               ,MAX_EVENT_SIZE = 0 KB
               ,MEMORY_PARTITION_MODE = NONE
               ,TRACK_CAUSALITY = ON
               ,STARTUP_STATE = OFF );

        ALTER EVENT SESSION [TS:Timeouts]
        ON SERVER
        STATE=START
    END;