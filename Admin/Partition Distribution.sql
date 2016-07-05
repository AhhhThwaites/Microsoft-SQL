/*
    File: Partition Distribution.sql
    Desc: Discovery regarding the implementation of partitioning and row distribution
    Date: 04/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  04/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @PartitionFnName NVARCHAR(128) 

SET @PartitionFnName = 'PF_LRAudit';

SELECT  OBJECT_SCHEMA_NAME(IDX.object_id, DB_ID()) + '.' + OBJECT_NAME(PT.object_id) AS FQN
       ,PT.index_id
       ,IDX.name AS IndexName
       ,PTN.name AS PartitionName
       ,SCH.name AS PartitionSchemeName
       ,PT.partition_number
       ,PT.rows
       ,PTRV.value AS PartitionRangeValue
       ,PT.data_compression_desc
FROM    sys.partitions AS PT
        INNER JOIN sys.indexes AS IDX
            ON IDX.index_id = PT.index_id
               AND IDX.object_id = PT.object_id
        INNER JOIN sys.objects AS OBJ
            ON OBJ.object_id = IDX.object_id
               AND OBJ.is_ms_shipped = 0
        INNER JOIN sys.partition_schemes AS SCH
            ON IDX.data_space_id = SCH.data_space_id
        INNER JOIN sys.partition_functions AS PTN
            ON PTN.function_id = SCH.function_id
        INNER JOIN sys.partition_range_values AS PTRV
            ON PTRV.function_id = PTN.function_id
               AND PT.partition_number = PTRV.boundary_id
WHERE   (PTN.name = @PartitionFnName OR @PartitionFnName IS NULL)
ORDER BY FQN
       ,IDX.index_id
       ,PT.partition_number;