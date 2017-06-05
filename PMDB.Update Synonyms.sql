
CREATE PROCEDURE [dbo].[UpdateSynonyms]
   @Database nvarchar(256), -- such as 'linkedserver.database' or just 'database'
   @Schema sysname, -- such as 'dbo' or 'P6'  
   @Base_Object_Name_Like nvarchar(50), -- such as '%PMDB%'
   @Object_Name nvarchar(50) 
AS

/*
'---------------------------------------------------------------------------------------
' Purpose:  This procedure creates Synonyms for the Primavera tables
' Example:  EXEC UpdateSynonyms '[LINKED_SERVER_NAME].PMDB', 'dbo', '%PMDB%', NULL
'			EXEC UpdateSynonyms 'PMDB_TEST', 'P6', '%PMDB%', NULL 
'---------------------------------------------------------------------------------------

*/

CREATE TABLE #Tables 
(
   TableID int identity(1,1) NOT NULL PRIMARY KEY CLUSTERED,
   Table_Name sysname
)
DECLARE
   @SQL nvarchar(4000),
   @SQL_Drop nvarchar(4000),
   @ID int

BEGIN
	IF (@Object_Name  IS NULL)
		SET @SQL = N'SELECT name FROM sys.synonyms WHERE base_object_name LIKE ''' + @Base_Object_Name_Like + ''''
	ELSE
		SET @SQL = N'SELECT ''' + @Object_Name + ''''
END 

	DECLARE @TableName nvarchar(100)
	INSERT #Tables EXEC sp_executesql @SQL
	SELECT @ID = MAX(TableID) FROM #Tables
	WHILE @ID > 0 BEGIN

		-- drop the existing SYNONYM
		SELECT @SQL = 'DROP SYNONYM ' + @Schema + '.' + tbl.Table_Name 
		FROM 
			#Tables tbl 
			INNER JOIN sys.synonyms syn ON syn.name = tbl.Table_Name 
		WHERE 
			tbl.TableID = @ID
		IF EXISTS (SELECT * FROM #Tables tbl INNER JOIN sys.synonyms syn ON syn.name = tbl.Table_Name WHERE tbl.TableID = @ID) BEGIN
			EXEC sp_executesql @SQL
		END

		--create synonyms here
		SELECT @SQL = 'CREATE SYNONYM [' + @Schema + '].' + Table_Name + ' FOR ' + @Database + '.dbo.' + Table_Name 
		FROM 
			#Tables 
		WHERE 
			TableID = @ID
		EXEC sp_executesql @SQL
		SELECT @TableName = Table_Name FROM #Tables WHERE TableID = @ID 
		SELECT @SQL = 'GRANT ALL ON [' + @Schema + '].' + @TableName + ' TO db_exec'
		EXEC sp_executesql @SQL
		SET @ID = @ID - 1

END


GO