/*'----------------------------------------------------------------------------
| Purpose:	To search deployed reports on the report server
| Note:		SQLCmdMode Script
'------------------------------------------------------------------------------
*/

:setvar _server "Server1"
:setvar _user "***username***"
:setvar _password "***password***"
:setvar _database "ReportServer"
:connect $(_server) -U $(_user) -P $(_password)

USE [$(_database)];
GO


DECLARE @ReportFolder AS VARCHAR(100)
DECLARE @ReportName AS VARCHAR(100)
DECLARE @ReportDescription AS VARCHAR(50)
DECLARE @CreatedBy AS VARCHAR(50)
DECLARE @CreatedDate AS DATETIME
DECLARE @ModifiedBy AS VARCHAR(50)
DECLARE @ModifiedDate AS DATETIME
DECLARE @ReportDefinition AS VARCHAR(50)
DECLARE @SearchFor AS VARCHAR(50)
DECLARE @SearchType AS VARCHAR(50)
DECLARE @all_value AS VARCHAR(50)

SET @ReportFolder = '<ALL>'
SET @ReportName = NULL
SET @ReportDescription = NULL
SET @CreatedBy = NULL
SET @CreatedDate = NULL
SET @ModifiedBy = NULL
SET @ModifiedDate = NULL
SET @ReportDefinition = NULL
SET @SearchFor = NULL
SET @SearchType = NULL   -- 'Report Name', 'Report Description', 'Report Definition'
SET @all_value = '<ALL>'

*/

;WITH
report_users 
AS
(
	SELECT UserID, SimpleUserName = UPPER(RIGHT(UserName, (LEN(UserName)-CHARINDEX('\',UserName)))) FROM dbo.Users
)
,
report_catalog
AS
(
	SELECT    
		  rpt.ItemID
		, rpt.CreatedById
		, rpt.ModifiedById
		, rpt.[Type]
		, rpt.[Name] 
		, rpt.[Description]
		, rpt.Parameter
		, CreationDate = CONVERT(DATETIME, CONVERT(VARCHAR(11), rpt.CreationDate, 13))
		, ModifiedDate = CONVERT(DATETIME, CONVERT(VARCHAR(11), rpt.ModifiedDate, 13))
		, ReportFolder = SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2) 
		, rpt.[Path]
		, URL_ReportFolder = 'http://' + Host_Name() + '/Reports/Pages/Report.aspx?ItemPath=%2f'  + SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2)  + '&ViewMode=List'
		, URL_Report = 'http://' + Host_Name() + '/Reports/Pages/Report.aspx?ItemPath=%2f'  + SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2)  + '%2f' + rpt.[Name]
		, ReportDefinition = CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), rpt.Content))  
	FROM 
		dbo.Catalog AS rpt
	WHERE 
		rpt.[Type] = 2
)
SELECT    
	  rpt.ItemID
	, rpt.[Name]
	, rpt.[Description]
	, rpt.Parameter
	, ReportCreatedBy = urc.SimpleUserName
	, ReportCreationDate = rpt.CreationDate 
	, ReportModifiedBy = urm.SimpleUserName
	, ReportModifiedDate = rpt.ModifiedDate 
	, rpt.ReportFolder
	, ReportPath = rpt.[Path]
	, rpt.URL_ReportFolder
	, rpt.URL_Report
	, rpt.ReportDefinition
	, CommandText = rpt.ReportDefinition
	, el.ExecutionLogCount
	, sc.SubscriptionCount
	, SearchForStr = ISNULL(@SearchFor, ' ') 
FROM  
	report_catalog AS rpt 
	LEFT JOIN (SELECT ExecutionLogCount = COUNT([ReportID]), ReportID FROM dbo.ExecutionLog GROUP BY ReportID) el ON el.ReportID = rpt.ItemID
	LEFT JOIN (SELECT SubscriptionCount = COUNT([Report_OID]), Report_OID FROM dbo.Subscriptions GROUP BY Report_OID) sc ON sc.Report_OID = rpt.ItemID
	LEFT JOIN report_users AS urc ON rpt.CreatedById = urc.UserID 
	LEFT JOIN report_users AS urm ON rpt.ModifiedById = urm.UserID 
WHERE 
	1=1
	AND (@all_value IN (@ReportFolder) OR rpt.ReportFolder IN(@ReportFolder))
	AND (@CreatedBy IS NULL OR urc.SimpleUserName LIKE '%' + @CreatedBy + '%')
	AND (@CreatedDate IS NULL OR rpt.CreationDate >= @CreatedDate)
	AND (@ModifiedBy IS NULL OR urm.SimpleUserName LIKE '%' + @ModifiedBy + '%')
	AND (@ModifiedDate IS NULL OR rpt.ModifiedDate >= @ModifiedDate)
	AND (
			@SearchFor IS NULL 
			OR (
				(rpt.[Name] LIKE '%' + @SearchFor + '%' AND (@all_value IN(@SearchType) OR 'Report Name' IN(@SearchType)))
				OR (rpt.[Description] LIKE '%' + @SearchFor + '%' AND (@all_value IN(@SearchType) OR 'Report Description' IN(@SearchType)) )
				OR (PATINDEX('%' + @SearchFor + '%', rpt.ReportDefinition) > 0 AND (@all_value IN(@SearchType) OR 'Report Definition' IN(@SearchType)) )   
				)
		)
