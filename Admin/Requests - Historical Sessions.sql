/*
    File: Requests - Historical Sessions.sql
    Desc: Use dm_exec_connections as the root, identify historical query information.
    Date: 05/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  05/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  EeC.session_id
       ,ExS.program_name
       ,ExS.host_name
       ,ExS.login_name
       ,EeC.auth_scheme
       ,DB_NAME(ExS.database_id) AS DatabaseName
       ,Qt.text
       ,EeC.last_read
       ,EeC.last_write
FROM    sys.dm_exec_connections AS EeC
        INNER JOIN sys.dm_exec_sessions AS ExS
            ON EeC.session_id = ExS.session_id
        OUTER APPLY sys.dm_exec_sql_text(EeC.most_recent_sql_handle) AS Qt
WHERE   ExS.program_name NOT LIKE 'Repl%'
        AND ExS.program_name NOT IN ('SQLAgent - Job Manager')
