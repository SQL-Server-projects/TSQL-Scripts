/*'---------------------------------------------------------------------------------------
' Purpose:	to search the reporting services execution log
'-----------------------------------------------------------------------------------------
*/

DECLARE @all_value AS VARCHAR(10)
DECLARE @LogStatus AS VARCHAR(50)
DECLARE @ReportFolder AS VARCHAR(450)
DECLARE @ReportName AS VARCHAR(450)
DECLARE @UserName AS VARCHAR(260)
DECLARE @GroupByColumn AS VARCHAR(50)
DECLARE @StartDate AS DATETIME
DECLARE @EndDate AS DATETIME

SET @all_value = '<ALL>'
SET @LogStatus = '<ALL>'
SET @ReportFolder = '...A Report Folder Name...'
SET @ReportName = '<ALL>' 
SET @UserName = '<ALL>'
SET @GroupByColumn = 'Report Folder'
SET @StartDate = NULL
SET @EndDate = NULL



;WITH
report_users 
AS
(
	SELECT UserID, UserName, SimpleUserName = UPPER(RIGHT(UserName, (LEN(UserName)-CHARINDEX('\',UserName)))) FROM dbo.Users
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
		, ReportName = rpt.[Name] 
		, rpt.[Description]
		, rpt.Parameter
		, CreationDate = CONVERT(DATETIME, CONVERT(VARCHAR(11), rpt.CreationDate, 13))
		, ModifiedDate = CONVERT(DATETIME, CONVERT(VARCHAR(11), rpt.ModifiedDate, 13))
		, ReportFolder = SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2) 
		, rpt.[Path]
		, URL_ReportFolder = 'http://' + Host_Name() + '/Reports/Pages/Report.aspx?ItemPath=%2f'  + SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2)  + '&ViewMode=List'
		, URL_Report = 'http://' + Host_Name() + '/Reports/Pages/Report.aspx?ItemPath=%2f'  + SUBSTRING(rpt.[Path], 2, Len(rpt.[Path])-Len(rpt.[Name])-2)  + '%2f' + rpt.[Name]
		, ReportDefinition = CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), rpt.Content))  
		, HostName = Host_Name()
	FROM 
		dbo.Catalog AS rpt
	WHERE 
		1=1
		AND rpt.[Type] = 2
)
SELECT 
 	GroupBy1 = 
 		CASE  
			WHEN @GroupByColumn = 'Report Name' THEN rpt.ReportName
			WHEN @GroupByColumn = 'Report Folder' THEN rpt.ReportFolder
			WHEN @GroupByColumn = 'User Id' THEN usr.SimpleUserName
			ELSE '<N/A>' 
		END
	, rpt.[Path]
	, rpt.ReportFolder
	, rpt.[Name]
	, rpt.URL_ReportFolder
	, rpt.URL_Report 
	, URL_Report_Filtered = rpt.URL_Report + '&rs:Command=Render&' + CONVERT(VARCHAR(2000), el.[Parameters])
	, UserName = usr.SimpleUserName
	, el.[Status]
	, el.TimeStart
	, el.[RowCount]
	, el.ByteCount
	, el.[Format]
	, el.[Parameters]
	, TotalSeconds = CONVERT(CHAR(8),DATEADD(ms,(el.TimeDataRetrieval + el.TimeProcessing + el.TimeRendering),0),108)
	, TimeDataRetrieval = CONVERT(CHAR(8),DATEADD(ms,el.TimeDataRetrieval,0),108) 
	, TimeProcessing = CONVERT(CHAR(8),DATEADD(ms,el.TimeProcessing,0),108)  
	, TimeRendering = CONVERT(CHAR(8),DATEADD(ms,el.TimeRendering,0),108) 
	, OrderbyDate = CAST(TimeStart AS DATETIME) 
FROM 
	report_catalog AS rpt 
	LEFT JOIN dbo.ExecutionLog AS el ON el.ReportID = rpt.ItemID
	LEFT JOIN report_users AS usr ON el.UserName = usr.UserName
WHERE 
	1=1
	AND (@all_value IN(@LogStatus) OR el.[Status] IN(@LogStatus))
	AND (@all_value IN (@ReportFolder) OR rpt.ReportFolder IN(@ReportFolder))
	AND (@all_value IN(@ReportName) OR rpt.ReportName IN(@ReportName))
	AND (@all_value IN(@UserName) OR usr.SimpleUserName IN(@UserName))
	AND (@StartDate IS NULL OR CONVERT(DATETIME, CONVERT(VARCHAR(11),el.TimeStart,13)) >= @StartDate)
	AND (@EndDate IS NULL OR CONVERT(DATETIME, CONVERT(VARCHAR(11),el.TimeStart,13)) <= @EndDate)
