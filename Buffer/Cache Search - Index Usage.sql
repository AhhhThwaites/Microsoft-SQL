/*
    File: Cache Search - Index Usage.sql
    Desc: Search the Plan Cache for usage of a given index within a specific database.
	Date: 21/09/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/09/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN
	DECLARE @IndexName NVARCHAR(128) = 'IDX_SomeIndexName';
	DECLARE @DatabaseName NVARCHAR(128) = 'DbNameHere'
	DECLARE @SQL NVARCHAR(MAX) 

	SET @SQL = 
	'WITH XMLNAMESPACES (DEFAULT ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'')
	SELECT  TOP 10 DB_NAME(E.dbid) AS [DBName]
		   ,OBJECT_NAME(E.objectid, dbid) AS [ObjectName]
		   ,P.cacheobjtype AS [CacheObjType]
		   ,P.objtype AS [ObjType]
		   ,E.query_plan.query(''count(//RelOp[@LogicalOp = ''''Index Scan'''' or @LogicalOp = ''''Clustered Index Scan'''']/*/Object[@Index=''''['+@IndexName+']''''])'') AS [ScanCount]
		   ,E.query_plan.query(''count(//RelOp[@LogicalOp = ''''Index Seek'''' or @LogicalOp = ''''Clustered Index Seek'''']/*/Object[@Index=''''['+@IndexName+']''''])'') AS [SeekCount]
		   ,E.query_plan.query(''count(//Update/Object[@Index=''''['+@IndexName+']''''])'') AS [UpdateCount]
		   ,P.refcounts AS [RefCounts]
		   ,P.usecounts AS [UseCounts]
		   ,E.query_plan AS [QueryPlan]
		   ,(SELECT	text AS [text()]
			 FROM	sys.dm_exec_sql_text(P.plan_handle)
			FOR
			 XML PATH('''')
				,TYPE
			) AS sql_text
	FROM    sys.dm_exec_cached_plans P
			CROSS APPLY sys.dm_exec_query_plan(P.plan_handle) E
	WHERE   E.dbid = DB_ID('''+@DatabaseName+''')
			AND E.query_plan.exist(''//*[@Index=''''['+@IndexName+']'''']'') = 1
	OPTION  (MAXDOP 1, RECOMPILE)'
	PRINT (@SQL);
	EXEC (@SQL);
END