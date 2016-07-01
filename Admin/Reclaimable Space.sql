/*
    File: Reclaimable Space.sql
    Desc: Returns Server wide usage, includes Current Size, Space Unused, SetSize and Percent Unused.
		  Don't shrink files unless you really have to, this causes fragmentation within your database.
	Date: 01/07/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  01/07/2016  none
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MinID INT
   ,@MaxID INT
   ,@DatabaseName NVARCHAR(128)
   ,@SQL VARCHAR(MAX);
	
--Set what files you want to see OPTIONS ARE; 'ALL', 'DATA', 'LOG'
IF OBJECT_ID('tempdb.dbo.##DatabaseFileSizes') IS NOT NULL
    DROP TABLE ##DatabaseFileSizes;

--Create table for Databasefiles
CREATE TABLE ##DatabaseFileSizes
    (
     [DatabaseID] INT
    ,[DataFile] VARCHAR(1000)
    ,[PhysicalName] VARCHAR(1000)
    ,[CurrentSizeMB] DECIMAL(15, 2)
    ,[UnUsedMB] DECIMAL(15, 2)
    );

DECLARE @VarDatabases TABLE
    (
     [DatabaseID] INT NOT NULL
    ,[DatabaseName] VARCHAR(100)
    );

--Populate
INSERT  INTO @VarDatabases
        SELECT  database_id
               ,[name]
        FROM    [sys].[databases]
        WHERE   [state_desc] = 'ONLINE'
                AND source_database_id IS NULL;

SELECT  @MinID = MIN([DatabaseID])
       ,@MaxID = MAX([DatabaseID])
FROM    @VarDatabases;

WHILE @MinID <= @MaxID
    BEGIN
        PRINT @MinID;
        PRINT @MaxID;

        SELECT  @DatabaseName = [DatabaseName]
        FROM    @VarDatabases
        WHERE   @MinID = [DatabaseID];

        SELECT  @SQL = 'USE [' + @DatabaseName + '];
		INSERT INTO ##DatabaseFileSizes 	
		SELECT	DB_ID() AS DatabaseID
				,name as DataFile
				,Physical_Name as [PhysicalName]
				,(size/128.0)
				,cast(size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int)/128.0 as DECIMAL(18,2))
		FROM	sys.database_files 
		WHERE	right(physical_name,3) in (''MDF'',''LDF'',''NDF'')';
PRINT @SQL
        EXEC (@SQL);

        SELECT  @MinID = MIN(DatabaseID)
        FROM    @VarDatabases
        WHERE   DatabaseID > @MinID;
    END;

SELECT  DB_NAME([DatabaseID]) AS DatabaseName
       ,[DataFile]
       ,[PhysicalName]
       ,[CurrentSizeMB]
       ,[UnUsedMB]
       ,([CurrentSizeMB] - [UnUsedMB]) AS [PotentialSize]
       ,CAST(([UnUsedMB] / [CurrentSizeMB]) * 100 AS DECIMAL(5, 2)) AS [PercentUnused]
FROM    ##DatabaseFileSizes;


