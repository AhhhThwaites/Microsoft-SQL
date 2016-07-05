/*
    File: Database - OS Distribution.sql
    Desc: Discovery of where databases are placed and current size. 
    Date: 04/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  04/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH	[CTE_Drives]
		  AS (SELECT	[Drive] = [dovs].[volume_mount_point]
					   ,[DatabaseName] = DB_NAME([mf].[database_id])
					   ,[total_MB] = CAST(([total_bytes] * 1.0) / 1048576 AS DECIMAL(18, 2))
					   ,[available_MB_Total] = CAST(([available_bytes] * 1.0) / 1048576 AS DECIMAL(18, 2))
					   ,[FilesOnDrive] = COUNT(*)
					   ,SUM([size]) AS [Size]
					   ,COUNT(DISTINCT [dovs].[database_id]) AS [DBCount]
			  FROM		[sys].[master_files] [mf]
						CROSS APPLY [sys].[dm_os_volume_stats]([mf].[database_id], [mf].[file_id]) [dovs]
			  GROUP BY	[dovs].[volume_mount_point]
					   ,DB_NAME([mf].[database_id])
					   ,CAST(([total_bytes] * 1.0) / 1048576 AS DECIMAL(18, 2))
					   ,CAST(([available_bytes] * 1.0) / 1048576 AS DECIMAL(18, 2))
			 )
	SELECT	[CTE_Drives].[DatabaseName]
		   ,UPPER([Drive]) AS [Drive]
		   ,CAST(([Size] * 1.0 / 128) AS DECIMAL(10, 2)) AS [DBSize]
		   ,[FilesOnDrive]
	FROM	[CTE_Drives]
	ORDER BY [CTE_Drives].[DatabaseName],Drive