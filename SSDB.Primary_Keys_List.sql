WITH
column_names  -- listing of all the columns used in the primary key
AS
(
	SELECT  
		  kc.object_id
		, kc.parent_object_id
		, PrimaryKeyName = QUOTENAME(OBJECT_NAME(kc.object_id))
		, SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME(kc.parent_object_id)) 
		, TableName = QUOTENAME(OBJECT_NAME(kc.parent_object_id))
		, ColumnName = COL_NAME(ob.object_id, ic.column_id)
		, ic.key_ordinal
		, key_number = CAST(kc.parent_object_id AS VARCHAR) + CAST(ic.key_ordinal AS VARCHAR)
		, parent_number = CAST(kc.parent_object_id AS VARCHAR) + CAST(ic.key_ordinal - 1 AS VARCHAR)
		, descending_key = CASE ic.is_descending_key WHEN 0 THEN 'ASC' ELSE 'DESC' END
		, clustered_desc = CASE INDEXPROPERTY(kc.parent_object_id, OBJECT_NAME(kc.object_id),'IsClustered') WHEN 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END
    FROM 
		sys.key_constraints kc
		INNER JOIN sys.objects ob on kc.parent_object_id = ob.object_id
		INNER JOIN sys.indexes AS I ON KC.unique_index_id = I.index_id AND KC.parent_object_id = I.object_id 
		INNER JOIN sys.index_columns ic ON I.object_id = IC.object_id AND I.index_id = IC.index_id
    WHERE 
		    kc.type = 'PK' 
		AND ob.type = 'U'
		AND ob.name not in ('dtproperties','sysdiagrams')  -- not true user tables
		--AND COL_NAME(ob.object_id, ic.column_id) = N'$(targetColumn)'
)
,
max_key_ordinal --get the max ordinal number for complete list of columns
AS
(
	SELECT 		  
		  object_id
		, parent_object_id 
		, max_ordinal_value = MAX(key_ordinal)
	FROM column_names
	GROUP BY
		  object_id
		, parent_object_id 
)
, 
primary_key_columns(object_id, parent_object_id, PrimaryKeyName, ColumnNames, SchemaName, TableName, key_ordinal, key_number, clustered_desc)  -- recursive query to get all the columns in a comma separated list
AS
(
	SELECT pt.object_id, pt.parent_object_id, pt.PrimaryKeyName, ColumnNames = CAST(pt.ColumnName + ' ' + pt.descending_key AS VARCHAR(MAX)), pt.SchemaName, pt.TableName, pt.key_ordinal, pt.key_number, pt.clustered_desc
	FROM column_names pt
	INNER JOIN column_names ch ON pt.key_number = ch.key_number 
	WHERE pt.key_ordinal = 1 -- parent record
	UNION ALL
	SELECT pt.object_id, pt.parent_object_id, pt.PrimaryKeyName, CAST(ch.ColumnNames + ', ' + pt.ColumnName + ' ' + pt.descending_key AS VARCHAR(MAX)), pt.SchemaName, pt.TableName, pt.key_ordinal, pt.key_number, pt.clustered_desc
	FROM column_names pt
	INNER JOIN primary_key_columns ch ON pt.parent_number = ch.key_number --recursive part
	WHERE pt.key_ordinal != 1  -- child record
)
SELECT 
	  pk.PrimaryKeyName
	, pk.SchemaName
	, pk.TableName
	, 'create_primary_key' = 'ALTER TABLE ' + pk.SchemaName + '.' + pk.TableName + ' ADD CONSTRAINT ' + pk.PrimaryKeyName + ' PRIMARY KEY ' + clustered_desc + ' (' + pk.ColumnNames + ') ' 
	, 'drop_primary_key' = 'ALTER TABLE ' + pk.SchemaName + '.' + pk.TableName + ' DROP CONSTRAINT ' + pk.PrimaryKeyName
FROM 
primary_key_columns pk
INNER JOIN max_key_ordinal mv ON mv.object_id = pk.object_id AND mv.parent_object_id = pk.parent_object_id AND mv.max_ordinal_value = pk.key_ordinal
