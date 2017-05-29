/*--------------------------------------------------------------------------------------------------------------------------------+
| Purpose:	User defined fields formatted values
| Note:		SQLCmdMode Script
+--------------------------------------------------------------------------------------------------------------------------------*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "PMDB_1"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO

WITH
project_filter
AS
(
	SELECT '12345' as proj_id
)
,
wbs_relate (wbs_id, parent_wbs_id, proj_id, wbs_format_name, wbs_short_name, wbs_name, wbs_level_nbr)
AS
(
	SELECT 
		  pwbs.wbs_id
		, pwbs.parent_wbs_id
		, pwbs.proj_id
		, cast(pwbs.wbs_short_name as varchar(max))
		, pwbs.wbs_short_name
		, pwbs.wbs_name
		, 0
	FROM 
		PROJWBS pwbs
		INNER JOIN PROJWBS rwbs ON pwbs.parent_wbs_id = rwbs.wbs_id
		INNER JOIN project_filter pf ON pwbs.proj_id = pf.proj_id 
	WHERE 
		pwbs.proj_node_flag = 'Y' -- parent record
	UNION ALL
	SELECT 
		  pwbs.wbs_id
		, pwbs.parent_wbs_id
		, pwbs.proj_id
		, rwbs.wbs_format_name + '.' + pwbs.wbs_short_name
		, pwbs.wbs_short_name
		, pwbs.wbs_name
		, wbs_level_nbr + 1
	FROM 
		PROJWBS pwbs
		INNER JOIN wbs_relate rwbs ON pwbs.parent_wbs_id = rwbs.wbs_id
		INNER JOIN project_filter pf ON pwbs.proj_id = pf.proj_id  
	WHERE 
		pwbs.proj_node_flag = 'N'  -- child record
)
,
udf_values_case 
AS
(
	SELECT 
		  uv.proj_id
		, ut.udf_type_label
		, udf_value = 
			CASE 
				WHEN ut.logical_data_type IN('FT_TEXT','FT_STATICTYPE') THEN CONVERT(VARCHAR, uv.udf_text) 
				WHEN ut.logical_data_type IN('FT_START_DATE','FT_END_DATE') THEN REPLACE(CONVERT(VARCHAR(11),uv.udf_date,113),' ','-')
				WHEN ut.logical_data_type IN('FT_FLOAT_2_DECIMALS','FT_INT', 'FT_MONEY')  THEN CONVERT(VARCHAR, uv.udf_number)
				ELSE '### The - ' + ut.logical_data_type + ' is NOT coded for. ###' 
			END
	FROM 
		UDFTYPE ut 
		INNER JOIN UDFVALUE uv ON ut.udf_type_id = uv.udf_type_id 
		INNER JOIN project_filter pf ON uv.proj_id = pf.proj_id
	)
,
activity_code_pivot
AS
(
	SELECT 
		  proj_id
		, task_id
		, [Region] 
		, [Discipline] 
		, [Asset Lead] 
		, [Responsible Engineer] 
		, [Priority] 
	FROM 
		(
		SELECT 
			  ta.proj_id
			, ta.task_id
			, ac.short_name 
			, at.actv_code_type
		FROM 
			TASKACTV ta 
			LEFT JOIN ACTVTYPE at ON at.actv_code_type_id = ta.actv_code_type_id
			LEFT JOIN ACTVCODE ac ON at.actv_code_type_id = ac.actv_code_type_id
			INNER JOIN project_filter pf ON ta.proj_id = pf.proj_id 
		WHERE 
			1=1
			AND at.actv_code_type IN('Region', 'Discipline', 'Asset Lead', 'Responsible Engineer', 'Priority')
		) pL
	PIVOT
	(
	MAX(short_name) 
	FOR actv_code_type 
	IN 
		(
		  [Region] 
		, [Discipline] 
		, [Asset Lead] 
		, [Responsible Engineer] 
		, [Priority] 
		)
	) AS pvt
)
, 
udf_values_pivot
AS
(
	SELECT 
		  proj_id
		, task_id
		, [Indicative Cost]
		, [Control Budget]	  
		, [Actual Cost]
		, [Asset Location]
		, [Focal Point] 
		, [Onsite Tech Support]
		, [Specific Discipline]
	FROM 
		(
		SELECT
			  pj.proj_id
			, tk.task_id 
			, uv.udf_type_label
			, uv.udf_value
		FROM 
			udf_values_case uv
			INNER JOIN PROJECT pj ON pj.proj_id = uv.proj_id
			INNER JOIN TASK tk ON pj.proj_id = tk.proj_id
			INNER JOIN project_filter pf ON uv.proj_id = pf.proj_id  
		WHERE 
			1=1
			AND tk.task_type IN('tt_mile','tt_finmile')
		) pL
	PIVOT
	(
	MAX(udf_value) 
	FOR udf_type_label 
	IN
		(
		  [Indicative Cost]   
		, [Control Budget]	  
		, [Actual Cost]
		, [Asset Location]
		, [Focal Point] 
		, [Onsite Tech Support]
		, [Specific Discipline]
		)
	) AS pvt
)
SELECT
	  ac.[Region]
	, ac.[Discipline] 
	, ac.[Asset Lead] 
	, udf.[Indicative Cost]
	, [Activity ID] = tk.task_code
	, [Activity Name] = tk.task_name
	, [Activity % Complete] = tk.phys_complete_pct
	, [Actual Start] = tk.act_start_date
	, [Actual Finish] = tk.act_end_date
	, [Start] = tk.early_start_date
	, [Finish] = tk.early_end_date	
	, udf.[Control Budget]
	, udf.[Actual Cost] 
	, [WBS Name] = wbs.wbs_name 
	, [WBS Path] = wbs.wbs_format_name
	, udf.[Asset Location] 
	, udf.[Focal Point] 
	, udf.[Onsite Tech Support] 
	, udf.[Specific Discipline]
	, ac.[Asset Lead1] 
	, ac.[Responsible Engineer] 
	, ac.[Asset Lead2] 
	, ac.[Priority] 
FROM 
	wbs_relate wbs
	INNER JOIN TASK tk ON tk.wbs_id = wbs.wbs_id AND tk.proj_id = wbs.proj_id
	INNER JOIN udf_values_pivot udf ON udf.proj_id = tk.proj_id AND udf.task_id = tk.task_id
	LEFT JOIN activity_code_pivot ac ON ac.task_id = tk.task_id

GO