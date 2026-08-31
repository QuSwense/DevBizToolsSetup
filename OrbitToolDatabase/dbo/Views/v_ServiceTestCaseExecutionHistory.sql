/*
    View: v_ServiceTestCaseExecutionHistory
    Description: Execution history for each test case.
*/
CREATE VIEW [dbo].[v_ServiceTestCaseExecutionHistory]
AS
SELECT 
    l.[Id] AS ExecutionLinkId,
    l.[ServiceTestSuiteExecutionAuditId],
    l.[ServiceTestCaseId],
    l.[ServiceResponseFileId],
    l.[ExecutedAt],
    l.[ExecutionCompletedAt],
    l.[HttpStatusCode],
    l.[HttpVersion],
    l.[HttpRequestDurationMs],
    l.[HttpContentType],
    l.[HttpContentLength],
    l.[ExecutionStatus] AS TestExecutionStatus,
    l.[ExecutionDetails] AS TestExecutionDetails,
    l.[ExecutedBy] AS TestExecutedBy,
    
    -- Test case details
    stc.[Name] AS TestCaseName,
    stc.[IsActive] AS TestCaseIsActive,
    
    -- Response file details
    srf.[Name] AS ResponseFileName,
    srf.[FileFormat] AS ResponseFileFormat,
    
    -- Suite details
    sts.[Id] AS SuiteId,
    sts.[Name] AS SuiteName,
    a.[ExecutionStatus] AS SuiteExecutionStatus,
    a.[ExecutedAt] AS SuiteExecutedAt,
    
    -- User details
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS ExecutedByFullName,
    
    -- Status description
    CASE 
        WHEN l.[ExecutionStatus] = 'Completed' THEN '✅ Success'
        WHEN l.[ExecutionStatus] = 'Failed' THEN '❌ Failed'
        WHEN l.[ExecutionStatus] = 'InProgress' THEN '⏳ In Progress'
        ELSE '⏸️ Pending'
    END AS StatusDisplay,
    
    -- Response time in seconds
    CAST(l.[HttpRequestDurationMs] / 1000.0 AS DECIMAL(10,2)) AS ResponseTimeSeconds

FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
INNER JOIN [dbo].[ServiceResponseFiles] srf ON l.[ServiceResponseFileId] = srf.[Id]
INNER JOIN [dbo].[ServiceTestSuiteExecutionAudits] a ON l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
INNER JOIN [dbo].[ServiceTestSuites] sts ON a.[ServiceTestSuiteId] = sts.[Id]
INNER JOIN [dbo].[Users] u ON l.[ExecutedBy] = u.[UserId];
GO