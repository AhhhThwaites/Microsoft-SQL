/*
    File: Mirror Failover.sql
    Desc: Checks @DatabaseName is currently in a mirror and the PRINCIPLE, failover executes after that.
    Date: 21/01/2016
    
    Version Change          Date        Notes
    1.0     Initial Commit  21/01/2016  none
*/

DECLARE @DatabaseName sysname = 'DBName';

DECLARE @CurrentRole VARCHAR(30);

SELECT  @CurrentRole = mirroring_role_desc
FROM    sys.database_mirroring
WHERE   DB_NAME(database_id) = @DatabaseName;

BEGIN
    IF ( @CurrentRole ) IS NULL
        BEGIN
            RAISERROR('database is not in a mirror',16,1);
            RETURN;
        END;

    IF ( @CurrentRole ) = 'MIRROR'
        BEGIN
            PRINT 'run this on the current PRINCIPLE...';
        END;

    IF ( @CurrentRole ) = 'PRINCIPAL'
        BEGIN
            IF ( SELECT mirroring_state_desc
                 FROM   sys.database_mirroring
                 WHERE  DB_NAME(database_id) = @DatabaseName
               ) = 'SYNCHRONIZED'
                BEGIN
                    PRINT 'SYNCHRONIZED, ready to failover';
                                  DECLARE @SQL VARCHAR(2000)
                                  
                                  SET @SQL = 'ALTER DATABASE ['+@DatabaseName+'] SET PARTNER FAILOVER'
                                  
                                  PRINT @SQL
                                  EXEC (@SQL)
                END;
            ELSE
                BEGIN
                    RAISERROR('DB is not SYNCHRONIZED, try again later or investigate issues',16,1);
                END;
        END;
END;
