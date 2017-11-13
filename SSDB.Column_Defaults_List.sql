
SELECT 
	  'Table Name' = ST.[name]  
	, 'Column Name' = SC.[name]  
	, 'Default Value' = SD.definition  
	, 'Constraint Name' = SD.[name]  
	, DROP_SCRIPT = 'ALTER TABLE [' + SCHEMA_NAME(SD.[schema_id]) + '].[' + OBJECT_NAME(SD.[parent_object_id]) + '] DROP CONSTRAINT [' + SD.[name] + ']; ' 
	, ADD_SCRIPT = 'ALTER TABLE [' + SCHEMA_NAME(SD.[schema_id]) + '].[' + OBJECT_NAME(SD.[parent_object_id]) + '] ADD CONSTRAINT [' + SD.[name] + '] DEFAULT ([dbo].[GetLoginName]()) FOR [' + SC.name + ']'
FROM 
	sys.tables ST 
	INNER JOIN sys.syscolumns SC ON ST.[object_id] = SC.[id] 
	INNER JOIN sys.default_constraints SD ON ST.[object_id] = SD.[parent_object_id] AND SC.colid = SD.parent_column_id
--WHERE 
--	SC.name IN('CRE_ID', 'LST_MDFD_ID')
