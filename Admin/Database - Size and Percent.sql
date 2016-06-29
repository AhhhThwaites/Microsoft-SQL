/*
    File: FileGroup Space Used.sql
    Desc: Returns information about used/unused FG and Files, change to a DB to use. 
    Date: 29/06/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  29/06/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH    CTE_Size
          AS ( SELECT   DB_NAME(MF.database_id) AS DBName
                       ,SUM(CAST(MF.size / 128.0 AS DECIMAL(20,3))) AS Size
               FROM     sys.master_files AS MF
               WHERE    MF.type <> 1
               GROUP BY DB_NAME(MF.database_id)
			   WITH ROLLUP
             )
    SELECT  S.DBName
           ,S.Size
		   ,CAST((S.Size/CA.Size)*100 AS DECIMAL(5,2)) AS PCTSize
    FROM    CTE_Size AS S
            CROSS APPLY ( SELECT    SUM(CAST(size / 128.0 AS DECIMAL(20,3))) AS Size
                          FROM      sys.master_files
						  WHERE		type <> 1
                        ) AS CA 
