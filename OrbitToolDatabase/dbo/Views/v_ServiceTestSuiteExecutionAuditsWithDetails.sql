/*
    View: v_ServiceTestSuiteExecutionAuditsWithDetails
    Description: Comprehensive view of test suite execution audits with test case results.
*/
CREATE VIEW [dbo].[v_ServiceTestSuiteExecutionAuditsWithDetails]
AS
SELECT 
    a.[Id] AS AuditId,
    a.[ServiceTestSuiteId],
    a.[ExecutedAt],
    a.[ExecutionCompletedAt],
    a.[ExecutionStatus] AS SuiteExecutionStatus,
    a.[ExecutionDetails] AS SuiteExecutionDetails,
    a.[ExecutedBy] AS SuiteExecutedBy,
    
    -- Suite details
    sts.[Name] AS SuiteName,
    sts.[Description] AS SuiteDescription,
    
    -- User details
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS ExecutedByFullName,
    u.[Email] AS ExecutedByEmail,
    
    -- Test case execution summaries (JSON array)
    (
        SELECT 
            l.[Id] AS ExecutionLinkId,
            stc.[Name] AS TestCaseName,
            l.[HttpStatusCode],
            l.[HttpVersion],
            l.[HttpRequestDurationMs],
            l.[HttpContentType],
            l.[HttpContentLength],
            l.[ExecutionStatus] AS TestExecutionStatus,
            l.[ExecutionDetails] AS TestExecutionDetails,
            l.[ExecutedAt] AS TestExecutedAt,
            l.[ExecutionCompletedAt] AS TestCompletedAt,
            srf.[Name] AS ResponseFileName
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
        LEFT JOIN [dbo].[ServiceResponseFiles] srf ON l.[ServiceResponseFileId] = srf.[Id]
        WHERE l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
        FOR JSON AUTO
    ) AS TestCaseExecutions,
    
    -- Summary statistics
    (
        SELECT COUNT(*) 
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        WHERE l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
    ) AS TotalTestCases,
    
    (
        SELECT COUNT(*) 
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        WHERE l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
          AND l.[ExecutionStatus] = 'Completed'
    ) AS SuccessfulTestCases,
    
    (
        SELECT COUNT(*) 
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        WHERE l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
          AND l.[ExecutionStatus] = 'Failed'
    ) AS FailedTestCases,
    
    -- Duration
    DATEDIFF(SECOND, a.[ExecutedAt], ISNULL(a.[ExecutionCompletedAt], GETDATE())) AS DurationSeconds,
    
    -- Average response time
    (
        SELECT AVG([HttpRequestDurationMs])
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        WHERE l.[ServiceTestSuiteExecutionAuditId] = a.[Id]
          AND l.[HttpRequestDurationMs] IS NOT NULL
    ) AS AvgResponseTimeMs

FROM [dbo].[ServiceTestSuiteExecutionAudits] a
INNER JOIN [dbo].[ServiceTestSuites] sts ON a.[ServiceTestSuiteId] = sts.[Id]
INNER JOIN [dbo].[Users] u ON a.[ExecutedBy] = u.[UserId];
GO