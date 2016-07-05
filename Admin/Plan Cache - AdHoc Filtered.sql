/*
    File: Plan Cache - AdHoc Filtered.sql
    Desc: Filtering recent query execution, look for certain fn/prc then filter to statement level.
	Date: 05/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  05/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MinutesBack INT = 10;

WITH    CTE_QS
          AS (SELECT    *
              FROM      sys.dm_exec_query_stats
              WHERE     last_execution_time > DATEADD(SECOND, -@MinutesBack, GETDATE())),
        CTE_inner
          AS (SELECT    C.creation_time AS PlanCreationTime
                       ,C.last_execution_time
                       ,C.execution_count
                       ,ST.text
                       ,SUBSTRING(ST.text, CASE WHEN C.statement_start_offset IN (0, NULL) THEN 1
                                                ELSE C.statement_start_offset / 2 + 1
                                           END, CASE WHEN C.statement_end_offset IN (0, -1, NULL) THEN LEN(ST.text)
                                                     ELSE C.statement_end_offset / 2 + 1
                                                END - CASE WHEN C.statement_start_offset IN (0, NULL) THEN 1
                                                           ELSE C.statement_start_offset / 2 + 1
                                                      END) AS QueryText
                       ,DB_NAME(ST.dbid) AS DatabaseName
                       ,OBJECT_SCHEMA_NAME(ST.objectid, ST.dbid) AS SchemaName
                       ,OBJECT_NAME(ST.objectid, ST.dbid) AS ObjectName
                       ,C.plan_handle
                       ,CAST((C.total_physical_reads * 1.0 / C.execution_count) AS DECIMAL(15, 2)) AS AveragePR
                       ,CAST((C.total_logical_reads * 1.0 / C.execution_count) AS DECIMAL(15, 2)) AS AverageLR
                       ,CAST((C.total_logical_writes * 1.0 / C.execution_count) AS DECIMAL(15, 2)) AS AverageLW
                       ,CAST(DATEADD(MILLISECOND, ((C.total_elapsed_time / 1000) / execution_count), CAST(CAST(GETDATE() AS DATE) AS DATETIME)) AS TIME(2)) AS AvTimeToRun
                       ,CAST(DATEADD(MILLISECOND, (( C.last_elapsed_time / 1000 )),CAST(CAST(GETDATE() AS DATE) AS DATETIME)) AS TIME(2)) AS LastRunTime
                       ,CAST(DATEADD(MILLISECOND, (( C.max_elapsed_time / 1000 )),CAST(CAST(GETDATE() AS DATE) AS DATETIME)) AS TIME(2)) AS MaxRunTime
                       ,C.last_worker_time
                       ,C.last_physical_reads
                       ,C.last_logical_writes
                       ,C.last_logical_reads
                       ,C.last_elapsed_time
              FROM      CTE_QS AS C
                        CROSS APPLY sys.dm_exec_sql_text(C.sql_handle) AS ST
              WHERE     ((ST.text LIKE '%CREATE FUNCTION% global.GetApp%')
						OR ST.text LIKE '%CREATE FUNCTION%\[global].\[GetApp]%' ESCAPE '\'))
    SELECT  *
    FROM    CTE_inner AS C

