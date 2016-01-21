/*
    File: Compression Savings.sql
    Desc: Checks at table level for compression savings
    Date: 21/01/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/01/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN    DECLARE @SchemaName sysname = 'laterooms'
       ,@TableName sysname = 'user'
       ,@IndexID INT
       ,@PartitionNumber INT;	--@CompressionSavings for results    DECLARE @CompressionSavings TABLE
        (
         SchemaName sysname
        ,TableName sysname
        ,index_id INT
        ,partition_number INT
        ,CurrentSizeKB NUMERIC(20,2)
        ,EstSizeKB NUMERIC(20,2)
        ,CurrentSizeSampleKB NUMERIC(20,2)
        ,EstSizeSampleKB NUMERIC(20,2)
        ,CompressionType VARCHAR(4)
        );	--insert ROW and PAGE level compression for given objects    BEGIN        INSERT  INTO @CompressionSavings
                (TableName
                ,SchemaName
                ,index_id
                ,partition_number
                ,CurrentSizeKB
                ,EstSizeKB
                ,CurrentSizeSampleKB
                ,EstSizeSampleKB
                )
                EXEC sys.sp_estimate_data_compression_savings
                    @SchemaName
                   ,@TableName
                   ,@IndexID
                   ,@PartitionNumber
                   ,'ROW';        UPDATE  @CompressionSavings
        SET     CompressionType = 'ROW'
        WHERE   CompressionType IS NULL;        
		INSERT  INTO @CompressionSavings
                (TableName
                ,SchemaName
                ,index_id
                ,partition_number
                ,CurrentSizeKB
                ,EstSizeKB
                ,CurrentSizeSampleKB
                ,EstSizeSampleKB
                )
                EXEC sys.sp_estimate_data_compression_savings
                    @SchemaName
                   ,@TableName
                   ,@IndexID
                   ,@PartitionNumber
                   ,'PAGE';

        UPDATE  @CompressionSavings
        SET     CompressionType = 'PAGE'
        WHERE   CompressionType IS NULL;
    END;

	--CTE results for easier manipulation of results if required
    WITH    CTE_Results
              AS ( SELECT   CS.SchemaName
                           ,CS.TableName
                           ,CS.index_id
                           ,CS.partition_number
                           ,CS.CompressionType
                           ,CS.CurrentSizeKB
                           ,CS.EstSizeKB
                           ,( 100 - CAST(CAST(CASE WHEN EstSizeKB = 0 THEN 1
                                                   ELSE EstSizeKB
                                              END AS DECIMAL(20,2)) / CAST (CASE WHEN CurrentSizeKB = 0 THEN 1
                                                                                 ELSE CurrentSizeKB
                                                                            END AS DECIMAL(20,2)) * 100 AS DECIMAL(20,2)) ) AS PercentSaving
                   FROM     @CompressionSavings AS CS
                 )
        SELECT  C.SchemaName
               ,C.TableName
               ,C.index_id
               ,C.partition_number
               ,C.CompressionType
               ,C.CurrentSizeKB
               ,C.EstSizeKB
               ,C.PercentSaving
        FROM    CTE_Results AS C
        ORDER BY C.SchemaName
               ,C.TableName
			   ,C.index_id
               ,C.PercentSaving DESC
END;
