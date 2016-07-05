/*
    File: Plan Cache - DML.sql
    Desc: Using the plan cache, find basic DML operations (not including MERGE).
	Date: 04/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  04/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH    CTE_PC
          AS (SELECT    CP.usecounts
                       ,CP.size_in_bytes
                       ,DB_NAME(ST.dbid) AS DatabaseName
                       ,ST.objectid
                       ,ST.number
                       ,ST.text
                       ,CP.plan_handle
              FROM      sys.dm_exec_cached_plans AS CP
                        CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) AS ST
              WHERE     ((ST.text LIKE '%INSERT INTO \[dbo].\[rates]%' ESCAPE '\')
                         OR (ST.text LIKE '%INSERT INTO dbo.rates%'))
                        OR ((ST.text LIKE '%UPDATE \[dbo].\[rates]%' ESCAPE '\')
                            OR (ST.text LIKE '%UPDATE dbo.rates%'))
                        OR ((ST.text LIKE '%DELETE \[dbo].\[rates]%' ESCAPE '\')
                            OR (ST.text LIKE '%DELETE dbo.rates%')))
    SELECT  C.usecounts
           ,C.DatabaseName
           ,C.objectid
           ,CASE WHEN C.text LIKE '%UPDATE%' THEN 'Update'
                 WHEN C.text LIKE '%INSERT%' THEN 'Insert'
                 ELSE 'Unknown'
            END AS SQLType
           ,C.text
           ,C.plan_handle
           ,ISNULL(QS.last_execution_time, PS.last_execution_time) AS last_execution_time
    FROM    CTE_PC AS C
            LEFT JOIN sys.dm_exec_query_stats AS QS
                ON QS.plan_handle = C.plan_handle
            LEFT JOIN sys.dm_exec_procedure_stats AS PS
                ON PS.plan_handle = C.plan_handle
OPTION  (MAXDOP 1);

