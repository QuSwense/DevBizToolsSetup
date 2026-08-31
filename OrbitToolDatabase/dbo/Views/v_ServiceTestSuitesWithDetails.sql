/*
    View: v_ServiceTestSuitesWithDetails
    Description: Comprehensive view of service test suites with test case details.
*/
CREATE VIEW [dbo].[v_ServiceTestSuitesWithDetails]
AS
SELECT 
    sts.[Id] AS TestSuiteId,
    sts.[Name] AS SuiteName,
    sts.[Description] AS SuiteDescription,
    sts.[IsActive] AS SuiteIsActive,
    sts.[RecordVersion] AS SuiteVersion,
    sts.[CreatedAt] AS SuiteCreatedAt,
    sts.[CreatedBy] AS SuiteCreatedBy,
    sts.[LastUpdatedAt] AS SuiteLastUpdatedAt,
    sts.[LastUpdatedBy] AS SuiteLastUpdatedBy,
    
    -- Linked Test Cases (JSON array with order)
    (
        SELECT 
            stc.[Id] AS TestCaseId,
            stc.[Name] AS TestCaseName,
            l.[ExecutionOrder],
            l.[IsActive] AS LinkIsActive,
            srf.[Name] AS RequestFileName
        FROM [dbo].[ServiceTestSuiteTestCaseLinks] l
        INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
        LEFT JOIN [dbo].[ServiceRequestFiles] srf ON stc.[ServiceRequestFileId] = srf.[Id]
        WHERE l.[ServiceTestSuiteId] = sts.[Id]
          AND stc.[IsActive] = 1
        ORDER BY l.[ExecutionOrder]
        FOR JSON AUTO
    ) AS TestCases,
    
    -- Count of test cases
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceTestSuiteTestCaseLinks] l
        WHERE l.[ServiceTestSuiteId] = sts.[Id]
          AND l.[IsActive] = 1
    ) AS TestCaseCount,
    
    -- Last execution audit
    (
        SELECT TOP 1
            [Id] AS AuditId,
            [ExecutedAt],
            [ExecutionCompletedAt],
            [ExecutionStatus],
            [ExecutedBy]
        FROM [dbo].[ServiceTestSuiteExecutionAudits] a
        WHERE a.[ServiceTestSuiteId] = sts.[Id]
        ORDER BY a.[ExecutedAt] DESC
        FOR JSON AUTO
    ) AS LastExecution,
    
    -- Total execution count
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceTestSuiteExecutionAudits] a
        WHERE a.[ServiceTestSuiteId] = sts.[Id]
    ) AS TotalExecutions

FROM [dbo].[ServiceTestSuites] sts;
GO