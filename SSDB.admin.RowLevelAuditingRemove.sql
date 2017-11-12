CREATE PROCEDURE [admin].[RowLevelAuditingRemove] 
	  @SchemaName NVARCHAR(50) = NULL
	, @TableName NVARCHAR(50) = NULL
AS
BEGIN
/*
'--------------------------------------------------------------------------------------------------------------------
' Purpose: Removes row level auditing columns to a table
' Example: EXEC admin.RowLevelAuditingRemove 'dbo', 'Users';
'--------------------------------------------------------------------------------------------------------------------


	-----------------------------------------------------
	-->>>>>>>>>>>>>>>>> FOR DEBUGGING <<<<<<<<<<<<<<<<<<<
	-----------------------------------------------------
	BEGIN
	DECLARE @SchemaName NVARCHAR(50)
	DECLARE @TableName NVARCHAR(50) 
	SET @SchemaName = 'dbo'
	SET @TableName = 'Users'
	-----------------------------------------------------
	-----------------------------------------------------

*/

	SET XACT_ABORT ON
	BEGIN TRANSACTION;
	SET NOCOUNT ON

	DECLARE @SqlCommand NVARCHAR(1000)
	DECLARE @CreatedId NVARCHAR(50)
	DECLARE @CreatedDate NVARCHAR(50)
	DECLARE @ModifiedId NVARCHAR(50)
	DECLARE @ModifiedDate NVARCHAR(50)

	SET @CreatedId = 'CreatedId'
	SET @CreatedDate = 'CreatedDate'
	SET @ModifiedId = 'ModifiedId'
	SET @ModifiedDate = 'ModifiedDate'

	SET @SqlCommand = 'DROP TRIGGER [' + @SchemaName + '].[TR_' + @TableName + '_LAST_UPDATED];' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP CONSTRAINT [DF_' + @TableName + '_' + @CreatedId + '];' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP CONSTRAINT [DF_' + @TableName + '_' + @CreatedDate + '];' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP CONSTRAINT [DF_' + @TableName + '_' + @ModifiedId + '];' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP CONSTRAINT [DF_' + @TableName + '_' + @ModifiedDate + '];' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP COLUMN ' + @CreatedId + ';' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP COLUMN ' + @CreatedDate + ';' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP COLUMN ' + @ModifiedId + ';' + CHAR(13);
	SET @SqlCommand += 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' DROP COLUMN ' + @ModifiedDate + ';' + CHAR(13);
	PRINT @SqlCommand
	EXEC (@SqlCommand)


	--PRINT 'ROLLBACK TRANSACTION... ';
	--ROLLBACK TRANSACTION;
	
	PRINT 'COMMIT TRANSACTION... '
	COMMIT TRANSACTION;

END

GO