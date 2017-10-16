SELECT DISTINCT 
	IndividualScript = 'EXEC sp_refreshview ''' + sc.name + '.' + so.name + ''''
FROM 
	sys.objects AS so 
	INNER JOIN sys.schemas sc ON sc.schema_id = so.schema_id
	INNER JOIN sys.sql_dependencies AS sed ON so.object_id = sed.object_id
WHERE       
	1=1
	AND so.type = 'V' 
	--AND OBJECT_NAME(sed.referenced_major_id) LIKE 'MyTable%'
