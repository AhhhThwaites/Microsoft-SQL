/*
    File: FileGroup Space Used.sql
    Desc: Returns information about used/unused FG and Files, change to a DB to use. 
    Date: 29/06/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  29/06/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH    CTE_Space
          AS ( SELECT   FG.name
                       ,SUM(CAST(( AU.total_pages * 8.0 ) / 1024 AS DECIMAL(20,2))) AS MB_InUse
                       ,CAST(( MBSize * 1.00 ) / 128 AS DECIMAL(20,2)) AS MBSize
                       ,COUNT(AU.allocation_unit_id) AS AllocationUnitCount
                       ,DSB.Files
                       ,FG.data_space_id
               FROM     sys.filegroups AS FG
                        LEFT JOIN sys.allocation_units AS AU
                            ON FG.data_space_id = AU.data_space_id
                        INNER JOIN ( SELECT data_space_id
                                           ,SUM(size) AS MBSize
                                           ,COUNT(*) AS Files
                                     FROM   sys.master_files
                                     WHERE  database_id = DB_ID()
                                     GROUP BY data_space_id
                                   ) AS DSB
                            ON DSB.data_space_id = FG.data_space_id
               GROUP BY FG.name
                       ,DSB.MBSize
                       ,DSB.Files
                       ,FG.data_space_id
             )
    SELECT  C.name
           ,C.data_space_id
           ,ISNULL(C.MB_InUse,0) AS MB_InUse
           ,C.AllocationUnitCount
           ,C.Files
           ,C.MBSize
           ,ISNULL(( C.MBSize - C.MB_InUse ),C.MBSize) AS FreeSpace
           ,ISNULL(CAST(( C.MB_InUse / C.MBSize ) * 100 AS DECIMAL(5,2)),0) AS PercentUsed
    FROM    CTE_Space AS C
    ORDER BY C.MB_InUse ASC;

