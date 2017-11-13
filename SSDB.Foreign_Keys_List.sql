WITH 
foreign_keys_list
AS
(
	SELECT
		  SchemaName = SCHEMA_NAME(F.schema_id) --+ '.'
        , TableName = OBJECT_NAME(F.parent_object_id) 
        , ForeignKeyName = F.name
        , ColumnName = COL_NAME(FC.parent_object_id, FC.parent_column_id) 
        , RefSchemaName = SCHEMA_NAME(RefObj.schema_id) 
        , RefTableName = OBJECT_NAME(F.referenced_object_id) 
        , RefColumnName = COL_NAME(FC.referenced_object_id, FC.referenced_column_id)
	FROM
		SYS.FOREIGN_KEYS AS F
		INNER JOIN SYS.FOREIGN_KEY_COLUMNS AS FC ON F.OBJECT_ID = FC.constraint_object_id
		INNER JOIN sys.objects RefObj ON RefObj.object_id = f.referenced_object_id
)
SELECT
	  ForeignKeyName
	, SchemaName 
	, TableName
	, ColumnName 
	, RefSchemaName
	, RefTableName 
	, RefColumnName 
	, create_foreign_key = 'ALTER TABLE ' + SchemaName + '.' + TableName + ' ADD CONSTRAINT ' + ForeignKeyName + ' FOREIGN KEY ' + '(' + ColumnName + ')' + ' REFERENCES ' + RefSchemaName + '.' + RefTableName + ' (' + RefColumnName + ')'
	, drop_foreign_key = 'ALTER TABLE ' + SchemaName + '.' + TableName + ' DROP CONSTRAINT ' + ForeignKeyName
FROM
	foreign_keys_list