/*--------------------------------------------------------------------------------------------------------------------------------+
| Purpose:	Remove orphan projects
| Note:		SQLCmdMode Script
+--------------------------------------------------------------------------------------------------------------------------------*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "PMDB_TEST"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO

PRINT '====================================================================='
PRINT 'Find orphan project ids. '
PRINT '====================================================================='
GO

SELECT  proj_id FROM project WHERE proj_id NOT IN(SELECT proj_id FROM projwbs)

PRINT '====================================================================='
PRINT 'remove orphan project ids. '
PRINT '====================================================================='
GO

--declare @ret integer, @msg varchar(255)
--BEGIN
--EXEC cascade_delete 'PROJECT','*****', @ret output, @msg output --replace with the proj_id from above
--END

PRINT '====================================================================='
PRINT 'Finished!'
PRINT '====================================================================='
GO