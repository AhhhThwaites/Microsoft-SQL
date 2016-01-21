/*
    File: Backup Loop with Compression.sql
    Desc: Checks @DatabaseName is currently in a mirror and the PRINCIPLE, failover executes after that.
    Date: 21/01/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/01/2016  none
*/

USE [master]
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN
	--User Variables
    DECLARE @bitCompression BIT = 1
			,@bitIncludeSystem BIT = 0
			,@varBackupLocation VARCHAR(500) --Can be left NULL (default will be used)

	--Internal Variables
	DECLARE	@intMinDB INT
		   ,@varDateSuffix VARCHAR(10) = REPLACE(CONVERT(VARCHAR(10),GETDATE(),103),'/','')
		   ,@varSQL VARCHAR(MAX);

	--If no location is provided, find the default
    IF @varBackupLocation IS NULL
        BEGIN
            DECLARE @BackupInfoTable TABLE
                (
                 KeyValue NVARCHAR(20)
                ,KeyData NVARCHAR(2000)
                );

            INSERT  INTO @BackupInfoTable
                    EXEC sys.xp_instance_regread
                        N'HKEY_LOCAL_MACHINE'
                       ,N'Software\Microsoft\MSSQLServer\MSSQLServer'
                       ,N'BackupDirectory';

            SELECT  @varBackupLocation = KeyData
            FROM    @BackupInfoTable;
        END;

	--Add '\' if it doesn't exists
	IF RIGHT(@varBackupLocation,1) != '\'
		SET @varBackupLocation = @varBackupLocation+'\'

	--Check compression is allowed!
    IF SERVERPROPERTY('EditionID') NOT IN (1804890536,1872460670,610778273,284895786,-2117995310,-1534726760)
        BEGIN
            SET @bitCompression = 0;
        END;

	--Setup backup list, excluding either system and always tempdb
	DECLARE @DatabaseTables TABLE
		(
		AutoID INT IDENTITY(1,1)
		,DatabaseName sysname
		)

	INSERT INTO @DatabaseTables
        SELECT  DB.name
        FROM    sys.databases AS DB
        WHERE   CASE WHEN @bitIncludeSystem = 1 THEN 0
                     ELSE 4
                END < DB.database_id
				AND DB.name NOT LIKE 'tempdb'
	
	--initial loop
	SELECT @intMinDB = MIN(AutoID) FROM @DatabaseTables

    WHILE @intMinDB <= (SELECT MAX(AutoID) FROM @DatabaseTables)
        BEGIN
            SELECT  @varSQL = 
					'BACKUP DATABASE '+QUOTENAME(DatabaseName,'[') + ' TO DISK = ''' 
					+ @varBackupLocation 
					+ DatabaseName 
					+ '_' + @varDateSuffix + '.BAK'''
					+ CASE WHEN @bitCompression = 1 THEN ' WITH COMPRESSION, ' ELSE ' WITH ' END
					+ ' INIT '
					+ ', FORMAT '
					+ ', STATS = 10'
			FROM	@DatabaseTables
			WHERE	AutoID = @intMinDB

            PRINT	(@varSQL);
            EXEC	(@varSQL);
		
			--loop control
            SELECT  @intMinDB = MIN(AutoID)
            FROM	@DatabaseTables
			WHERE	AutoID>@intMinDB
        END;
END;