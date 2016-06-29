/*
    File: Compression - Script 4.sql
    Desc: Testing! 
    Date: 06/04/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  06/04/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE [CompressionTest];
GO

BEGIN
	--NONE
	ALTER INDEX [IX:Composite01] 
	ON [dbo].[SMSArchive] 
	REBUILD WITH (DATA_COMPRESSION = NONE, MAXDOP = 1);

	EXEC [dbo].[ObjectSizeSummary]
		'dbo'
	   ,'SMSArchive';

	--ROW level
	ALTER INDEX [IX:Composite01] 
	ON [dbo].[SMSArchive] 
	REBUILD WITH (DATA_COMPRESSION = ROW, MAXDOP = 1);

	EXEC [dbo].[ObjectSizeSummary]
		'dbo'
	   ,'SMSArchive';

	--PAGE level
	ALTER INDEX [IX:Composite01] 
	ON [dbo].[SMSArchive] 
	REBUILD WITH (DATA_COMPRESSION = PAGE, MAXDOP = 1);

	EXEC [dbo].[ObjectSizeSummary]
		'dbo'
	   ,'SMSArchive';
END;