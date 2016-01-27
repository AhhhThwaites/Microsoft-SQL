/*
    File: User Trace.sql
    Desc: Extended event sessions to capture user queries
    Date: 26/01/2015
    
    Version Change          Date        Notes
    1.0     Initial Commit  26/01/2016  none
*/

IF EXISTS ( SELECT  *
            FROM    sys.dm_xe_sessions
            WHERE   name = 'TS:UserTrace' )
    BEGIN
        DROP EVENT SESSION [TS:UserTrace] ON SERVER; 
    END;
GO

--Create XE session
IF NOT EXISTS ( SELECT  *
                FROM    sys.dm_xe_sessions
                WHERE   name = 'TS:UserTrace' )
    BEGIN
        CREATE EVENT SESSION [TS:UserTrace] ON SERVER
        ADD EVENT sqlserver.sql_batch_completed (
            ACTION ( sqlserver.plan_handle,sqlserver.username )
            WHERE ( [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[username],N'Domain\UserName')
                    OR [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[username],N'Domain\UserName2')
                    OR [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[username],N'Domain\UserName3')
                  ) )
        ADD TARGET package0.pair_matching (  SET begin_event = N'sqlserver.sql_batch_completed'
                                            ,begin_matching_columns = N'batch_text'
                                            ,end_event = N'sqlserver.sql_statement_completed'
                                            ,end_matching_columns = N'statement' )
        WITH (  MAX_MEMORY = 4096 KB
               ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
               ,MAX_DISPATCH_LATENCY = 30 SECONDS
               ,MAX_EVENT_SIZE = 0 KB
               ,MEMORY_PARTITION_MODE = NONE
               ,TRACK_CAUSALITY = OFF
               ,STARTUP_STATE = OFF );

		ALTER EVENT SESSION [TS:UserTrace]
		ON SERVER
		STATE=START
    END;

