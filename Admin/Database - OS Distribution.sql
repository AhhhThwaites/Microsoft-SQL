/*
    File: Database - OS Distribution.sql
    Desc: Discovery of where databases are placed and current size. 
    Date: 04/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  04/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH    CTE_Drives
          AS ( SELECT   Drive = dovs.volume_mount_point
                       ,LogicalName = dovs.logical_volume_name
                       ,Total = CAST(( total_bytes * 1.0 ) / 1048576 AS DECIMAL(18,2))
                       ,ABTotal = CAST(( available_bytes * 1.0 ) / 1048576 AS DECIMAL(18,2))
                       ,FilesOnDrive = COUNT(*)
					   ,SUM(size) AS Size
                       ,COUNT(DISTINCT dovs.database_id) AS DBCount
               FROM     sys.master_files mf
                        CROSS APPLY sys.dm_os_volume_stats(mf.database_id,mf.FILE_ID) dovs
               GROUP BY dovs.volume_mount_point
                       ,dovs.logical_volume_name
                       ,CAST(( total_bytes * 1.0 ) / 1048576 AS DECIMAL(18,2))
                       ,CAST(( available_bytes * 1.0 ) / 1048576 AS DECIMAL(18,2))
             )
    SELECT  @@SERVERNAME AS ServerName
           ,Drive
           ,LogicalName
           ,Total
           ,ABTotal
		   ,CAST((Size*1.0/128) AS DECIMAL(10,2)) AS DBSize
           ,FilesOnDrive
           ,DBCount
           ,CAST(ABTotal / Total * 100 AS DECIMAL(4,2)) AS PercentUsed
           ,100 - CAST(ABTotal / Total * 100 AS DECIMAL(4,2)) AS PercentLeft
    FROM    CTE_Drives 
