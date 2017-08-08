/*--------------------------------------------------------------------------+
| Purpose:	Remove database locks on the server
| Note:		SQLCmdMode Script
+---------------------------------------------------------------------------*/


:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "PMDB_TEST"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO


PRINT '====================================================================='
PRINT 'show the blocked processes. '
PRINT '====================================================================='
GO

SELECT DB_NAME(dbid) as 'Database Name', * FROM master.dbo.sysprocesses WITH (NOLOCK) 
WHERE BLOCKED <> 0
--DB_NAME(dbid) = 'PMDB_TEST'  -- change the database name here

PRINT '====================================================================='
PRINT 'show the blocked process record. '
PRINT '====================================================================='
GO

SELECT DB_NAME(dbid) AS 'Database Name', * FROM master.dbo.sysprocesses 
WHERE SPID = 212  -- update the spid here

PRINT '====================================================================='
PRINT 'get the sql statement of the blocked process for the ticket. '
PRINT '====================================================================='
GO

DBCC INPUTBUFFER (212)  -- update the spid here

PRINT '====================================================================='
PRINT 'remove the blocked process. '
PRINT '====================================================================='
GO

--KILL 212  

PRINT '====================================================================='
PRINT 'Finished!'
PRINT '====================================================================='
GO
