/*
    File: Transaction Log Loop.sql
    Desc: Finds all files of type (TL) and restores with no recovery until the last file is parsed. 
    Date: 21/01/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/01/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN
	DECLARE	@FileExt CHAR(6) = '.sqb'
	   ,@DIR VARCHAR(100) = 'F:\Cleansed\Laterooms_InvTesting\'
	   ,@Debug BIT = 1;

	SET NOCOUNT ON; 
	
	DECLARE	@CMD VARCHAR(200); 

	SET @CMD = 'DIR "' + @DIR + '*' + @FileExt + '"';

	IF OBJECT_ID('tempdb.dbo.#tmpCMDOutput') IS NOT NULL
		DROP TABLE [#tmpCMDOutput];

	CREATE TABLE [#tmpCMDOutput]
		(
		 [ID] INT IDENTITY(1, 1)
		,[CMDOutput] VARCHAR(400)
		);

	INSERT	INTO [#tmpCMDOutput]
			EXEC [sys].[xp_cmdshell]
				@CMD;

	--remove the header info
	DELETE	FROM [#tmpCMDOutput]
	WHERE	[ID] < 6;

	DELETE	FROM [#tmpCMDOutput]
	WHERE	[ID] IN (SELECT TOP 3
							[ID]
					 FROM	[#tmpCMDOutput]
					 ORDER BY [ID] DESC);

	--Add Info required
	ALTER TABLE [#tmpCMDOutput]
	ADD		[FileDate] DATETIME
	,[FileName] VARCHAR(100);

	--Set to the English format
	SET DATEFORMAT DMY;

	--Update newly added fields
	UPDATE	[#tmpCMDOutput]
	SET		[FileDate] = CAST(LTRIM(RTRIM(REPLACE(SUBSTRING([CMDOutput], 1, 18), '  ', ' '))) AS DATETIME)
		   ,[FileName] = LTRIM(REVERSE(SUBSTRING(REVERSE([CMDOutput]), 1, CHARINDEX(' ', REVERSE([CMDOutput])))));

	DECLARE	@iMin INT;
	DECLARE	@iMax INT;

	SELECT	@iMin = MIN([ID])
		   ,@iMax = MAX([ID])
	FROM	[#tmpCMDOutput];

	WHILE @iMin <= @iMax
		BEGIN
			SELECT	@CMD = CASE	WHEN [ID] = @iMax
								THEN N'-SQL "RESTORE LOG [laterooms_inv] FROM DISK = '''+@DIR + [FileName] + ''' WITH RECOVERY"'
								ELSE N'-SQL "RESTORE LOG [laterooms_inv] FROM DISK = '''+@DIR + [FileName]
									 + ''' WITH NORECOVERY"'
						   END
			FROM	[#tmpCMDOutput]
			WHERE	[ID] = @iMin;
				
			PRINT @CMD;
			IF @Debug = 0
				BEGIN
					EXECUTE [master]..[sqlbackup]
						@CMD;
				END;
			--loop control
			SELECT	@iMin = MIN([ID])
			FROM	[#tmpCMDOutput]
			WHERE	[ID] > @iMin;
		END;
END;
