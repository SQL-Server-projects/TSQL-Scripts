CREATE PROCEDURE [dbo].[RowLevelAuditAdd] 
		@DatabaseName NVARCHAR(50) = NULL
	, @SchemaName NVARCHAR(50) = NULL
	, @TableName NVARCHAR(50) = NULL
AS
BEGIN

/*
'--------------------------------------------------------------------------------------------------------------------
' Purpose: Adds row level auditing columns to a table
' Example: EXEC dbo.RowLevelAuditAdd 'YourDatabase', 'dbo', 'ORGN';
' Note:    The table must have a primary key to create the update trigger
'--------------------------------------------------------------------------------------------------------------------

	-----------------------------------------------------
	-->>>>>>>>>>>>>>>>> FOR DEBUGGING <<<<<<<<<<<<<<<<<<<
	-----------------------------------------------------
	BEGIN
	DECLARE @DatabaseName NVARCHAR(50)
	DECLARE @SchemaName NVARCHAR(50)
	DECLARE @TableName NVARCHAR(50) 
	SET @DatabaseName = 'YourDatabase'
	SET @SchemaName = 'dbo'
	SET @TableName = 'ORGN'
	-----------------------------------------------------
	-----------------------------------------------------

	--remove the table if exists
	IF OBJECT_ID('dbo.ORGN', 'U') IS NOT NULL 
	  DROP TABLE dbo.ORGN; 

	--create the table
	CREATE TABLE [dbo].[ORGN] (
		[ORGN_ID]       INT             IDENTITY (1, 1) NOT NULL,
		[ORGN_ABBR]     VARCHAR (5)     NOT NULL,
		[ORGN_NAME]     VARCHAR (100)   NULL
	);

	--Add the keys
	ALTER TABLE [dbo].[ORGN]
		ADD CONSTRAINT [PK_ORGN] PRIMARY KEY NONCLUSTERED ([ORGN_ID] ASC);
	ALTER TABLE [dbo].[ORGN]
		ADD CONSTRAINT [UK_ORGN] UNIQUE NONCLUSTERED ([ORGN_ABBR] ASC);

	--Add some test records
	INSERT INTO dbo.ORGN (ORGN_ABBR, ORGN_NAME) VALUES('AABA', 'Altaba Inc');
	INSERT INTO dbo.ORGN (ORGN_ABBR, ORGN_NAME) VALUES('AAPL', 'Apple Inc');
	INSERT INTO dbo.ORGN (ORGN_ABBR, ORGN_NAME) VALUES('GOOG', 'Alphabet Inc');
	INSERT INTO dbo.ORGN (ORGN_ABBR, ORGN_NAME) VALUES('MSFT', 'Microsoft Corporation');
	INSERT INTO dbo.ORGN (ORGN_ABBR, ORGN_NAME) VALUES('TSLA', 'Tesla Inc');

	--test procedure
	EXEC dbo.RowLevelAuditAdd 'YourDatabase', 'dbo', 'ORGN';

*/

	SET XACT_ABORT ON
	BEGIN TRANSACTION;
	SET NOCOUNT ON

	DECLARE @SqlCommand NVARCHAR(1000)
	DECLARE @TableKey NVARCHAR(1000)
	DECLARE @UserName NVARCHAR(50)
	DECLARE @CreatedId NVARCHAR(50)
	DECLARE @CreatedDate NVARCHAR(50)
	DECLARE @ModifiedId NVARCHAR(50)
	DECLARE @ModifiedDate NVARCHAR(50)
	DECLARE @TodayDate NVARCHAR(50)

	SET @CreatedId = 'CreatedId'
	SET @CreatedDate = 'CreatedDate'
	SET @ModifiedId = 'ModifiedId'
	SET @ModifiedDate = 'ModifiedDate'
	SET @UserName = LOWER(LEFT(RIGHT(SYSTEM_USER,(LEN(SYSTEM_USER)-CHARINDEX('\',SYSTEM_USER))), 50))
	SET @TodayDate = FORMAT(GETDATE(), 'dd-MMM-yyyy HH:mm:ss', 'en-US' )

	PRINT '=====================================================================';
	PRINT 'START - ALTER [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + ']... ';

		IF COL_LENGTH(@DatabaseName + '.' + @SchemaName + '.' + @TableName, @CreatedId) IS NULL
		BEGIN

			PRINT '=====================================================================';
			PRINT 'START - ADD COLUMN [' + @CreatedId + ']... ';

			PRINT '1. alter table add ' + @CreatedId + ' column... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD [' + @CreatedId + '] [NVARCHAR](50) NULL'
			EXEC (@SqlCommand)

			PRINT '2. update new column to a value... ' + @UserName;			
			SET @SqlCommand = 'UPDATE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] SET [' + @CreatedId + '] =''' + @UserName + ''' WHERE [' + @CreatedId + '] IS NULL'
			EXEC (@SqlCommand)

			PRINT '3. alter table alter new column add constraints... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ALTER COLUMN [' + @CreatedId + '] [NVARCHAR](50) NOT NULL'
			EXEC (@SqlCommand)

			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [DF_' + @TableName + '_' + @CreatedId + ']  DEFAULT (LOWER(LEFT(RIGHT(SYSTEM_USER,(LEN(SYSTEM_USER)-CHARINDEX(''\'',SYSTEM_USER))), 50))) FOR [' + @CreatedId + ']'
			EXEC (@SqlCommand)

			PRINT '4. add column description... ';
			EXEC [sys].sp_addextendedproperty @name=N'MS_Description', @value=N'Who created the record' , @level0type=N'SCHEMA',@level0name=@SchemaName, @level1type=N'TABLE',@level1name=@TableName, @level2type=N'COLUMN',@level2name=@CreatedId;
				
			PRINT 'END - ADD COLUMN [' + @CreatedId + ']... ';
			PRINT '=====================================================================';
		END

		IF COL_LENGTH(@DatabaseName + '.' + @SchemaName + '.' + @TableName, @CreatedDate) IS NULL
		BEGIN

			PRINT '=====================================================================';
			PRINT 'START - ADD COLUMN [' + @CreatedDate + ']... ';

			PRINT '1. alter table add ' + @CreatedDate + ' column... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD [' + @CreatedDate + '] [DATETIME] NULL'
			EXEC (@SqlCommand)
							
			PRINT '2. update new column to a value... ' + @TodayDate;	
			SET @SqlCommand = 'UPDATE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] SET [' + @CreatedDate + '] = ''' + @TodayDate+ ''' WHERE [' + @CreatedDate + '] IS NULL'
			EXEC (@SqlCommand)

			PRINT '3. alter table alter new column add constraints... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ALTER COLUMN [' + @CreatedDate + '] [DATETIME] NOT NULL'
			EXEC (@SqlCommand)

			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [DF_' + @TableName + '_' + @CreatedDate + ']  DEFAULT (GETDATE()) FOR [' + @CreatedDate + ']'
			EXEC (@SqlCommand)

			PRINT '4. add column description... ';
			EXEC [sys].sp_addextendedproperty @name=N'MS_Description', @value=N'The date and time the record was created' , @level0type=N'SCHEMA',@level0name=@SchemaName, @level1type=N'TABLE',@level1name=@TableName, @level2type=N'COLUMN',@level2name=@CreatedDate;
				
			PRINT 'END - ADD COLUMN [' + @CreatedDate + ']... ';
			PRINT '=====================================================================';
		END

		IF COL_LENGTH(@DatabaseName + '.' + @SchemaName + '.' + @TableName, @ModifiedId) IS NULL
		BEGIN

			PRINT '=====================================================================';
			PRINT 'START - ADD COLUMN [' + @ModifiedId + ']... ';

			PRINT '1. alter table add ' + @ModifiedId + ' column... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD [' + @ModifiedId + '] [NVARCHAR](50) NULL'
			EXEC (@SqlCommand)

			PRINT '2. update new column to a value... ' + @UserName;			
			SET @SqlCommand = 'UPDATE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] SET [' + @ModifiedId + '] =''' + @UserName + ''' WHERE [' + @ModifiedId + '] IS NULL'
			EXEC (@SqlCommand)

			PRINT '3. alter table alter new column add constraints... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ALTER COLUMN [' + @ModifiedId + '] [NVARCHAR](50) NOT NULL'
			EXEC (@SqlCommand)

			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [DF_' + @TableName + '_' + @ModifiedId + ']  DEFAULT (LOWER(LEFT(RIGHT(SYSTEM_USER,(LEN(SYSTEM_USER)-CHARINDEX(''\'',SYSTEM_USER))), 50))) FOR [' + @ModifiedId + ']'
			EXEC (@SqlCommand)

			PRINT '4. add column description... ';
			EXEC [sys].sp_addextendedproperty @name=N'MS_Description', @value=N'Who modified the record' , @level0type=N'SCHEMA',@level0name=@SchemaName, @level1type=N'TABLE',@level1name=@TableName, @level2type=N'COLUMN',@level2name=@ModifiedId;
				
			PRINT 'END - ADD COLUMN [' + @ModifiedId + ']... ';
			PRINT '=====================================================================';
		END

		IF COL_LENGTH(@DatabaseName + '.' + @SchemaName + '.' + @TableName, @ModifiedDate) IS NULL
		BEGIN

			PRINT '=====================================================================';
			PRINT 'START - ADD COLUMN [' + @ModifiedDate + ']... ';

			PRINT '1. alter table add ' + @ModifiedDate + ' column... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD [' + @ModifiedDate + '] [DATETIME] NULL'
			EXEC (@SqlCommand)
							
			PRINT '2. update new column to a value... ' + @TodayDate;	
			SET @SqlCommand = 'UPDATE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] SET [' + @ModifiedDate + '] = ''' + @TodayDate+ ''' WHERE [' + @ModifiedDate + '] IS NULL'
			EXEC (@SqlCommand)

			PRINT '3. alter table alter new column add constraints... ';
			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ALTER COLUMN [' + @ModifiedDate + '] [DATETIME] NOT NULL'
			EXEC (@SqlCommand)

			SET @SqlCommand = 'ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [DF_' + @TableName + '_' + @ModifiedDate + ']  DEFAULT (GETDATE()) FOR [' + @ModifiedDate + ']'
			EXEC (@SqlCommand)

			PRINT '4. add column description... ';
			EXEC [sys].sp_addextendedproperty @name=N'MS_Description', @value=N'The date and time the record was modified' , @level0type=N'SCHEMA',@level0name=@SchemaName, @level1type=N'TABLE',@level1name=@TableName, @level2type=N'COLUMN',@level2name=@ModifiedDate;
				
			PRINT 'END - ADD COLUMN [' + @ModifiedDate + ']... ';
			PRINT '=====================================================================';
		END

		IF NOT EXISTS (SELECT * FROM [sys].[triggers] WHERE [object_id] = OBJECT_ID(N'[' + @SchemaName + '].[TR_' + @TableName + '_LAST_UPDATED]'))
		BEGIN

			PRINT '=====================================================================';
			PRINT 'START - ADD TRIGGER [TR_' + @TableName + '_LAST_UPDATED]... ';

			PRINT '1. get primary key from information schema';
			SET @SqlCommand = 'USE ' + @DatabaseName + '; '
			SET @SqlCommand += ' SELECT '  
			SET @SqlCommand += ' @TableKey = COALESCE(@TableKey, '''') + CASE WHEN [ORDINAL_POSITION] = 1 THEN ''ON'' ELSE ''AND'' END + '' t.'' + [COLUMN_NAME] + '' = i.'' + [COLUMN_NAME] + '' '''
			SET @SqlCommand += ' FROM'
			SET @SqlCommand += ' [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE]'
			SET @SqlCommand += ' WHERE'
			SET @SqlCommand += ' OBJECTPROPERTY(OBJECT_ID([CONSTRAINT_SCHEMA] + ''.'' + QUOTENAME([CONSTRAINT_NAME])), ''IsPrimaryKey'') = 1 '
			SET @SqlCommand += ' AND [TABLE_NAME] = ''' + @TableName + ''''
			SET @SqlCommand += ' AND [TABLE_SCHEMA] = ''' + @SchemaName + ''''
			SET @SqlCommand += ' ORDER BY [ORDINAL_POSITION]'
			EXEC sp_executeSQl @SqlCommand, N'@TableKey NVARCHAR(1000) OUTPUT', @TableKey OUTPUT

			PRINT '2. build trigger dynamically';
			SET @SqlCommand = 'USE ' + @DatabaseName + '; '
			SET @SqlCommand += ' CREATE TRIGGER [' + @SchemaName + '].[TR_' + @TableName + '_LAST_UPDATED]' + CHAR(13);
			SET @SqlCommand += ' ON [' + @SchemaName + '].[' + @TableName + ']' + CHAR(13);
			SET @SqlCommand += ' AFTER UPDATE' + CHAR(13);
			SET @SqlCommand += ' AS' + CHAR(13);
			SET @SqlCommand += ' BEGIN' + CHAR(13);
			SET @SqlCommand += CHAR(9) + ' IF NOT UPDATE(' + @ModifiedDate + ')' + CHAR(13);
			SET @SqlCommand += CHAR(9) + ' BEGIN' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + ' UPDATE t' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + ' SET' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + '   t.' + @ModifiedDate + ' = CURRENT_TIMESTAMP' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + ' , t.' + @ModifiedId + ' = LOWER(LEFT(RIGHT(SYSTEM_USER,(LEN(SYSTEM_USER)-CHARINDEX(''\'',SYSTEM_USER))), 50))' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + ' FROM [' + @SchemaName + '].[' + @TableName + '] AS t' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + ' INNER JOIN inserted AS i' + CHAR(13);
			SET @SqlCommand += CHAR(9) + CHAR(9) + @TableKey + ';' + CHAR(13);
			SET @SqlCommand += CHAR(9) + ' END' + CHAR(13);
			SET @SqlCommand += ' END;' + CHAR(13);
			EXEC (@SqlCommand)

			PRINT '3. enable trigger';
			SET @SqlCommand = 'USE ' + @DatabaseName + '; '
			SET @SqlCommand += ' ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] ENABLE TRIGGER [TR_' + @TableName + '_LAST_UPDATED]';
			EXEC (@SqlCommand)

			PRINT 'END - ADD TRIGGER [' + @ModifiedDate + ']... ';
			PRINT '=====================================================================';
		END


	PRINT 'END - ALTER [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + ']... ';
	PRINT '=====================================================================';

	--PRINT '******* ROLLBACK TRANSACTION ******* ';
	--ROLLBACK TRANSACTION;

	PRINT '******* COMMIT TRANSACTION ******* ';
	COMMIT TRANSACTION;

END

GO
