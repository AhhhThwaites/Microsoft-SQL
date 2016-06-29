/*
    File: Compression - Script 2.sql
    Desc: Populates CompressionTest with generic mobile data.
    Date: 06/04/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  06/04/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE [CompressionTest];
GO
BEGIN
	--Test data/Table
	IF OBJECT_ID('dbo.SMSArchive') IS NOT NULL
		BEGIN
			PRINT '...dropping table: [dbo].[SMSArchive]'
			DROP TABLE [dbo].[SMSArchive];
		END;

	CREATE TABLE [dbo].[SMSArchive]
		(
		 [SMSArchiveID] INT IDENTITY(1, 1)
							CONSTRAINT [PK_SMSArchive:SMSArchiveID] PRIMARY KEY
		,[SMSMessage] VARCHAR(459) NULL
		,[ToNumber] VARCHAR(11) NULL
		,[SMSProvID] INT NULL
		,[ResponseCode] VARCHAR(255) NULL
		,[SenderID] INT NULL
		,[FromNumber] VARCHAR(20) NULL
		,[N_ID] VARCHAR(50) NULL
		,[SMSAccountID] INT NULL
		);

	/*Generating a few GB of data*/
	--SMS Numbers, (1000 x N) to allow for decent page compression
	IF OBJECT_ID('tempdb.dbo.#tmpSMSNumbers') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSMSNumbers;
		END;

	CREATE TABLE [#tmpSMSNumbers] ([C1] VARCHAR(11));

	DECLARE	@i INT = 1;
	WHILE @i <= 1000
		BEGIN
			INSERT	INTO [#tmpSMSNumbers]
					([C1])
			VALUES	(LEFT('07' + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
						  + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
						  + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)), 11));

			SET @i = @i + 1;
		END;

	SET @i = 1;
	WHILE @i <= 1000000
		BEGIN
			INSERT	INTO [dbo].[SMSArchive]
					([SMSMessage]
					,[ToNumber]
					,[SMSProvID]
					,[ResponseCode]
					,[SenderID]
					,[FromNumber]
					,[N_ID]
					,[SMSAccountID])
			SELECT TOP 1
					'Welcome to [' + (SELECT	CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
									 ) + '], ' + [C1] AS [SMSMessage]
				   ,[C1] AS [ToNumber]
				   ,(SELECT	CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
					) AS [SMSProvID]
				   ,CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
					+ CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) AS [ResponseCode]
				   ,(SELECT	CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
					) AS [SenderID]
				   ,LEFT('07' + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
						 + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10))
						 + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)) + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10)), 11) AS [FromNumber]
				   ,NULL AS [N_ID]
				   ,NULL AS [SMSAccountID]
			FROM	[#tmpSMSNumbers]
			ORDER BY NEWID();

			SET @i = @i + 1;
		END;

		CREATE NONCLUSTERED INDEX [IX:Composite01] ON [dbo].[SMSArchive] ([SMSMessage])

		CREATE NONCLUSTERED INDEX [IX:Composite02] ON [dbo].[SMSArchive] ([ToNumber])
END;