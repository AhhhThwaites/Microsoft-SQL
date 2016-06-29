/*
    File: Compression - Script 3.sql
    Desc: Create useful objects.
    Date: 06/04/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  06/04/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE [CompressionTest];
GO

IF OBJECT_ID('[dbo].[ObjectSizeSummary]') IS NOT NULL
	DROP PROC [dbo].[ObjectSizeSummary];
GO

CREATE PROC [dbo].[ObjectSizeSummary]
	(
	 @SchemaName NVARCHAR(126)
	,@ObjectName NVARCHAR(126)
	)
AS
	BEGIN	
		SELECT	[SCH].[name] AS [SchemaName]
			   ,[O].[name] AS [TableName]
			   ,[i].[name] AS [IndexName]
			   ,[i].[index_id]
			   ,[p].[rows] AS [#Records]
			   ,CAST(CAST([a].[total_pages] AS DECIMAL(18, 3)) * 8 / 1024 AS DECIMAL(18, 3)) AS [Reserved(mb)]
			   ,CAST(CAST([a].[used_pages] AS DECIMAL(18, 3)) * 8 / 1024 AS DECIMAL(18, 3)) AS [TotalUsed(mb)]
			   ,CAST(CAST([a].[data_pages] AS DECIMAL(18, 3)) * 8 / 1024 AS DECIMAL(18, 3)) AS [DataSpace(mb)]
			   ,CAST((CAST([a].[used_pages] AS DECIMAL(18, 3)) - CAST([a].[data_pages] AS DECIMAL(18, 3))) * 8 / 1024 AS DECIMAL(18, 3)) AS [IndexSpace(mb)]
		FROM	[sys].[indexes] AS [i]
				INNER JOIN [sys].[partitions] AS [p]
					ON [i].[object_id] = [p].[object_id]
					   AND [i].[index_id] = [p].[index_id]
				INNER JOIN [sys].[allocation_units] AS [a]
					ON [p].[partition_id] = [a].[container_id]
				INNER JOIN [sys].[tables] AS [O]
					ON [i].[object_id] = [O].[object_id]
				INNER JOIN [sys].[schemas] AS [SCH]
					ON [SCH].[schema_id] = [O].[schema_id]
		WHERE	[O].[name] LIKE @ObjectName
				AND [SCH].[name] = @SchemaName
		ORDER BY [i].[index_id] ASC;
	END;
GO
