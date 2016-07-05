/*
    File: Requests - Active Sessions.sql
    Desc: Diagnostic real-time query information.
    Date: 29/06/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  29/06/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  DB_NAME(R.database_id) AS DatabaseName
       ,CAST(R.start_time AS TIME(0)) AS start_time
	   ,S.login_time
	   ,S.last_request_start_time
	   ,S.last_request_end_time
       ,R.session_id AS SPID
       ,R.blocking_session_id AS BlockedSPID
       ,R.cpu_time
       ,R.reads
       ,R.logical_reads
       ,R.writes
       ,DATEDIFF(SECOND,R.start_time,GETDATE()) AS SecRan
       ,S.host_name
       ,S.program_name
       ,R.command
       ,S.[status] AS SessionStatus
       ,R.[status] AS RequestStatus
       ,R.wait_type
       ,R.last_wait_type
       ,R.wait_resource
       ,S.login_name
       ,S.total_elapsed_time
       ,SUBSTRING(T.text,CASE WHEN R.statement_start_offset IN ( 0,NULL ) THEN 1
                              ELSE R.statement_start_offset / 2 + 1
                         END,CASE WHEN R.statement_end_offset IN ( 0,-1,NULL ) THEN LEN(T.text)
                                  ELSE R.statement_end_offset / 2 + 1
                             END - CASE WHEN R.statement_start_offset IN ( 0,NULL ) THEN 1
                                        ELSE R.statement_start_offset / 2 + 1
                                   END) AS QueryText
       ,DEQP.query_plan
FROM    sys.dm_exec_requests AS R
        INNER JOIN sys.dm_exec_sessions AS S
            ON R.session_id = S.session_id
		LEFT JOIN sys.dm_exec_connections AS SDEC 
			ON SDEC.session_id = S.session_id
        OUTER APPLY sys.dm_exec_sql_text(ISNULL(R.plan_handle, SDEC.most_recent_sql_handle)) AS T
        OUTER APPLY sys.dm_exec_query_plan(ISNULL(R.plan_handle, SDEC.most_recent_sql_handle)) AS DEQP
WHERE   @@SPID <> R.session_id
        AND R.session_id >= 50
        AND S.program_name NOT LIKE 'DatabaseMail%'
ORDER BY R.start_time ASC;
