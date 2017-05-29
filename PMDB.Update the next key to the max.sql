/*--------------------------------------------------------------------------------------------------------------------------------+
| Purpose:	Update the next key to the max
| Note:		SQLCmdMode Script
+--------------------------------------------------------------------------------------------------------------------------------*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "PMDB_TEST"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO

SET XACT_ABORT ON
BEGIN TRANSACTION

PRINT '====================================================================='
PRINT 'create a script for key errors and show the max key values and next key values'
PRINT '====================================================================='
GO

DECLARE @S NVARCHAR(MAX) = ''

;WITH
key_table_list
AS
(
	SELECT 
		  key_name
		, key_seq_num
		, table_name = LEFT(key_name, CHARINDEX('_',key_name,  0)-1)
		, column_name = RIGHT(key_name, LEN(key_name) - CHARINDEX('_',key_name,  0)) 
	FROM 
		NEXTKEY 
)
,
single_script
AS
(
	SELECT
		[RowNumber]= ROW_NUMBER() OVER(ORDER BY tl.table_name)
		, script = 'SELECT table_name =''' + tl.table_name + ''', max_key_seq_num = MAX(' + tl.column_name + '), key_seq_num = ' 
		+ CAST(tl.key_seq_num AS VARCHAR) + ', KeyError = CASE WHEN MAX(' + tl.column_name + ') > ' + CAST(tl.key_seq_num AS VARCHAR) 
		+ ' THEN ''EXEC dbo.getnextkeys N''''' + tl.key_name + ''''', '' + CAST(MAX(' + tl.column_name + ') - ' + CAST(tl.key_seq_num AS VARCHAR) + ' + 1 AS VARCHAR) + '', @NewKeyStart OUTPUT'' ELSE NULL END FROM ' + tl.table_name 
	FROM 
		key_table_list tl
		INNER JOIN sys.objects ob ON ob.name = tl.table_name
	WHERE 
		1=1
		AND ob.type = 'U'
) 
SELECT @S = @S + CASE WHEN [RowNumber] != 1 THEN ' UNION ' ELSE '' END + script
FROM 
single_script
EXEC ('SELECT * FROM (' + @S+ ') AS se WHERE KeyError IS NOT NULL')
GO

PRINT '====================================================================='
PRINT 'update next key to number of missing increments '
PRINT '====================================================================='
GO

--declare @val as int 
--declare @NewKeyStart as int 
--set @val = (select max(task_id) from task) 
---- before 

--select key_seq_num from nextkey where key_name='task_task_id' 
--select max(task_id) from task 
--Print @val 

--EXEC dbo.getnextkeys @tabcol = N'task_task_id', @nkeys = 893, @startkey = @NewKeyStart OUTPUT 

----after 
--select key_seq_num from nextkey where key_name='task_task_id' 
--select max(task_id) from task 

PRINT '====================================================================='
PRINT 'Finished!'
PRINT '====================================================================='
GO

ROLLBACK TRANSACTION
--COMMIT TRANSACTION   