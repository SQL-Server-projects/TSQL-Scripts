/*-----------------------------------------------------------------------------+
| Purpose:	Remove user sessions
| Note:		SQLCmdMode Script
+------------------------------------------------------------------------------*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "PMDB_TEST"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO

PRINT '====================================================================='
PRINT 'The first step is to find out the user_id of the user that we wish to remove. '
PRINT '====================================================================='
GO

DECLARE @LANID varchar(50)
DECLARE @USER_ID varchar(50)
SET @LANID = 'NetworkUserIdHere' -- replace the user name here

SELECT @USER_ID = user_id FROM users WHERE LOWER(user_name) LIKE LOWER('%' + @LANID + '%');

UPDATE usession SET delete_session_id = 0 , delete_date = GETDATE() WHERE user_id = @USER_ID;
GO

SELECT * FROM usession ORDER BY HOST_NAME
GO

PRINT '====================================================================='
PRINT 'Remove a session if the job has not cleared it. '
PRINT '====================================================================='
GO

--DELETE FROM usession WHERE session_id = 123456 -- replace this session_id with the one you want to remove

PRINT '====================================================================='
PRINT 'Finished!'
PRINT '====================================================================='
GO
