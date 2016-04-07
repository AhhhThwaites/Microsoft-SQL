/*
    File: Compression - Script 1.sql
    Desc: Sets up a CompressionTest database.
    Date: 06/04/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  06/04/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--Compression Test Script
IF EXISTS ( SELECT	*
			FROM	[sys].[databases]
			WHERE	[name] = 'CompressionTest' )
	BEGIN
		DROP DATABASE [CompressionTest];
	END;
GO

BEGIN

	DECLARE	@DatabaseName sysname = 'CompressionTest'
	   ,@DataLocation VARCHAR(400)
	   ,@LogLocation VARCHAR(400)
	   ,@DataSize VARCHAR(10) = '500MB'
	   ,@DataGrowth VARCHAR(10) = '128MB'
	   ,@MaxDataSize VARCHAR(10) = '1GB'
	   ,@LogSize VARCHAR(10) = '500MB'
	   ,@MaxLogSize VARCHAR(10) = '1GB'
	   ,@LogGrowth VARCHAR(10) = '128MB';

	DECLARE	@BackupInfoTable TABLE
		(
		 [KeyValue] NVARCHAR(20)
		,[KeyData] NVARCHAR(2000)
		);

	INSERT	INTO @BackupInfoTable
			EXEC [sys].[xp_instance_regread]
				N'HKEY_LOCAL_MACHINE'
			   ,N'Software\Microsoft\MSSQLServer\MSSQLServer'
			   ,N'DefaultData';

	INSERT	INTO @BackupInfoTable
			EXEC [sys].[xp_instance_regread]
				N'HKEY_LOCAL_MACHINE'
			   ,N'Software\Microsoft\MSSQLServer\MSSQLServer'
			   ,N'DefaultLog';

	SELECT	@DataLocation = (SELECT	[KeyData] AS [Data]
							 FROM	@BackupInfoTable
							 WHERE	[KeyValue] = 'DefaultData'
							)
		   ,@LogLocation = (SELECT	[KeyData] AS [Data]
							FROM	@BackupInfoTable
							WHERE	[KeyValue] = 'DefaultLog'
						   );

	DECLARE @strSQL VARCHAR(2000)

	SET @strSQL = 
		'CREATE DATABASE ['+@DatabaseName+'] ON PRIMARY'+CHAR(13)
		+'(NAME = N'''+@DatabaseName+'_data'''+CHAR(13)
		+',FILENAME= N'''+@DataLocation+'\'+@DatabaseName+'_data.mdf'''+CHAR(13)
		+',SIZE= '+@DataSize+CHAR(13)
		+',MAXSIZE= '+@MaxDataSize+CHAR(13)
		+',FILEGROWTH= '+@DataGrowth+')'+CHAR(13)
		+'LOG ON'+CHAR(13)
		+'(NAME = N'''+@DatabaseName+'_log'''+CHAR(13)
		+',FILENAME= N'''+@DataLocation+'\'+@DatabaseName+'_log.ldf'''+CHAR(13)
		+',SIZE= '+@LogSize+CHAR(13)
		+',MAXSIZE= '+@MaxLogSize+CHAR(13)
		+',FILEGROWTH= '+@LogGrowth+');'+CHAR(13)

	PRINT	(@strSQL)
	EXEC	(@strSQL)

END;
