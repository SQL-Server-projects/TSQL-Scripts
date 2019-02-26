/*+---------------------------------------------------------------------------
| Purpose:	To check for non-service accounts
| Note:		SQLCmdMode Script --> on the SSMS menu bar "Query" | "SQLCMD Mode"
+-----------------------------------------------------------------------------
*/

:setvar _server "YourServerName" -- change the server here
:setvar _database "master"
:connect $(_server)

USE [$(_database)];
GO

:setvar login_name "" -- to search for an individual account enter it here e.g. "Domain\UserName"


SET XACT_ABORT ON
BEGIN TRANSACTION;

PRINT '=====================================================================';
PRINT 'define all services accounts ... ';

SELECT tbl.* INTO #service_accounts FROM (VALUES
	  ('##MS_PolicyEventProcessingLogin##')
	, ('##MS_PolicyTsqlExecutionLogin##')
	, ('NT AUTHORITY\SYSTEM')
	, ('NT Service\MSSQLSERVER')
	, ('NT SERVICE\SQLSERVERAGENT')
	, ('NT SERVICE\SQLTELEMETRY')
	, ('NT SERVICE\SQLWriter')
	, ('NT SERVICE\Winmgmt')
	, ('public')
	, ('sa')
) tbl ([Login_Name]) 

PRINT '=====================================================================';
PRINT 'check databases owners ... ';

	SELECT 
		  [Server_Name] = @@SERVERNAME
		, [Database_Name] = db.[name]
		, [Login_Name] = sl.[Name]
		, [CommandToRun] = (CASE WHEN db.[is_read_only] = 1 THEN '-- Remove ReadOnly State' WHEN db.[state_desc] = 'ONLINE' THEN 'ALTER AUTHORIZATION on DATABASE::[' + db.[name] + '] to [sa];' ELSE '-- Turn On ' END)
		--, [Database_ID] = db.[database_id]
		--, [Current_State] = db.[state_desc]
		--, [Read_Only] = db.[is_read_only]
	FROM 
		[master].[sys].[databases] AS db
		INNER JOIN [master].[sys].[syslogins] AS sl ON db.[owner_sid] = sl.[sid]
	WHERE 
		1=1
		AND sl.[Name] NOT IN(SELECT [Login_Name] FROM #service_accounts)
		AND (sl.[Name] = N'$(login_name)' OR N'$(login_name)' = N'')
	ORDER BY 
		db.[Name]

PRINT '=====================================================================';
PRINT 'check databases users ... ';

	DECLARE @dbs_users TABLE 
		(
		  [Database_Name] SYSNAME
		, [User_Name] SYSNAME
		, [Login_Type] SYSNAME
		, [Associated_Role] VARCHAR(MAX)
		, [Create_Date] DATETIME
		, [Modify_Date] DATETIME
		)

	INSERT @dbs_users
	EXEC sp_MSforeachdb '
	USE [?]
	SELECT 
		  [Database_Name] = ''?''
		, [User_Name] = CASE dp.[name] WHEN ''dbo'' THEN (SELECT SUSER_SNAME([owner_sid]) FROM [master].[sys].[databases] WHERE [name] =''?'') ELSE dp.[name] END
		, [Login_Type] = dp.[type_desc]
		, [Associated_Role] = isnull(USER_NAME(dm.role_principal_id),'''')
		, dp.[create_date]
		, dp.[modify_date]
	FROM 
		[sys].[database_principals] AS dp
		LEFT JOIN [sys].[database_role_members] AS dm ON dp.[principal_id] = dm.[member_principal_id]
	WHERE 
		1=1
		AND dp.[sid] IS NOT NULL 
		AND dp.[sid] NOT IN (0x00) 
		AND dp.[is_fixed_role] != 1 
		AND dp.[name] NOT LIKE ''##%'''

	SELECT 
		  [Server_Name] = @@SERVERNAME
		, [Database_Name]
		, [User_Name]
		, [Create_Date]
		, [Modify_Date]
		, [Permissions_User] = STUFF((
				SELECT ',' + CONVERT(VARCHAR(500), [Associated_Role])
				FROM @dbs_users AS dbu2
				WHERE dbu1.[Database_Name] = dbu2.[Database_Name]
					AND dbu1.[User_Name] = dbu2.[User_Name]
				FOR XML PATH('')
				), 1, 1, '')
		--, [Login_Type]
	FROM 
		@dbs_users AS dbu1
	WHERE 
		1=1
		AND [User_Name] NOT IN(SELECT [Login_Name] FROM #service_accounts)
		AND [Login_Type] = 'WINDOWS_USER'
		AND ([User_Name] = N'$(login_name)' OR N'$(login_name)' = N'')
	GROUP BY 
		  [Database_Name]
		, [User_Name]
		, [Create_Date]
		, [Modify_Date]
		--, [Login_Type]
	ORDER BY 
		  [Database_Name]
		, [User_Name]

PRINT '=====================================================================';
PRINT 'check agent jobs ... ';

	SELECT 
		  [Server_Name] = @@SERVERNAME
		, [SQL_Agent_Job_Name] = sj.[name]
		, [Job_Owner] = sl.[name]
		, [CommandToRun] = 'EXEC [msdb].[dbo].[sp_update_job] @job_id=N''' + CAST(sj.[job_id] AS VARCHAR(150)) + ''', @owner_login_name=N''sa'' '
		--, sj.[description]
		--, sc.[name]
	FROM 
		[msdb].[dbo].[sysjobs] AS sj
		INNER JOIN [master].[sys].[syslogins] AS sl ON sj.[owner_sid] = sl.[sid]
		INNER JOIN [msdb].[dbo].[syscategories] AS sc ON sc.[category_id] = sj.[category_id]
	WHERE 
		1=1
		AND sl.[Name] NOT IN(SELECT [Login_Name] FROM #service_accounts)
		AND (sl.[name] = N'$(login_name)' OR N'$(login_name)' = N'')
	ORDER BY 
		sj.[name]

PRINT '=====================================================================';
PRINT 'check report subscriptions ... ';

	IF DB_ID('ReportServer') IS NOT NULL
		SELECT DISTINCT
			  [Server_Name] = @@SERVERNAME
			, [Report_Name] = rp.[Name]
			, [Subscription_Owner] = ou.[UserName]
			, [Subscription_Owner_ID] = ou.[UserID]
			--, sb.[Report_OID]
		FROM 
			[ReportServer].[dbo].[Subscriptions] AS sb
			INNER JOIN [ReportServer].[dbo].[Catalog] AS rp ON rp.[ItemID] = sb.[Report_OID]
			INNER JOIN [ReportServer].[dbo].[Users] AS ou ON ou.[UserID] = sb.[OwnerID]
		WHERE 
			1=1
			AND ou.[UserName] NOT IN(SELECT [Login_Name] COLLATE Latin1_General_CI_AS FROM #service_accounts)
			AND (ou.[UserName] = N'$(login_name)' OR N'$(login_name)' = N'')

PRINT '******* ROLLBACK TRANSACTION ******* ';
ROLLBACK TRANSACTION;

--PRINT '******* COMMIT TRANSACTION ******* ';
--COMMIT TRANSACTION;