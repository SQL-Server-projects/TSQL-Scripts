/*
|--------------------------------------------------------------------------------------------------
| Purpose:		To show all the Reporting Services folder permissions
| References:	How to create new permission groups https://www.mssqltips.com/sqlservertip/2793/sql-server-reporting-services-2012-permissions/
|				How to query folder permissions http://stackoverflow.com/questions/16920251/sql-server-reporting-services-2008-r2-folder-and-report-security
| Notes:		To deploy this report to the main report page, you must use "Upload File"
|				SQLCmdMode Script
|--------------------------------------------------------------------------------------------------
*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "ReportServer"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO


DECLARE @all_value AS VARCHAR(50)
DECLARE @UserName AS VARCHAR(50)

SET @all_value = '<ALL>'
SET @UserName = '<ALL>'


;WITH 
catalog_type_description
AS
(
	SELECT tbl.* FROM (VALUES
	  ( 1, 'Folder')
	, ( 2, 'Report')
	, ( 3, 'Resource')
	, ( 4, 'Linked Report')
	, ( 5, 'Data Source')
	, ( 6, 'Report Model')
	, ( 8, 'Shared Dataset')
	, ( 9, 'Report Part')
	) tbl ([TypeID], [TypeDescription]) 
	WHERE TypeID = 1
)
, 
nonreport_folders
AS
(
	SELECT tbl.* FROM (VALUES
	  ( 'Images')
	, ( 'SharedDataSets')
	, ( 'Data Sources')
	, ( 'contents')
	, ( '')
	) tbl ([FolderName]) 
)
, 
user_list
AS
(
	SELECT
		  usr.UserID
		, usr.UserName
		, UserNameFormat = 
			CASE 
				WHEN CHARINDEX('\', usr.UserName) > 0 THEN UPPER(SUBSTRING(usr.UserName ,CHARINDEX('\', usr.UserName) + 1, LEN(usr.UserName)))
				ELSE usr.UserName 
			END 
	FROM 
		dbo.Users usr
)
	SELECT 
		  FolderName = cat.[Name]
		, FolderPath = cat.Path
		, rol.RoleName
		, usr.UserNameFormat
	FROM 
		dbo.[Catalog] cat
		INNER JOIN catalog_type_description tpd ON cat.[Type] = tpd.TypeID	
		LEFT JOIN dbo.PolicyUserRole urol ON urol.PolicyID = cat.PolicyID
		LEFT JOIN dbo.Roles rol ON urol.RoleID = rol.RoleID
		LEFT JOIN dbo.Policies pol ON urol.PolicyID = pol.PolicyID
		LEFT JOIN user_list usr ON urol.UserID = usr.UserID
		LEFT JOIN nonreport_folders nrf ON nrf.FolderName = cat.Name
	WHERE 
		1=1
		AND nrf.FolderName IS NULL
		AND (@all_value IN(@UserName) OR usr.UserNameFormat IN(@UserName))
