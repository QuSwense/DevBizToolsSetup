/*
    View: v_ServiceTestCasesWithDetails
    Description: Comprehensive view of service test cases with request file details.
*/
CREATE VIEW [dbo].[v_ServiceTestCasesWithDetails]
AS
SELECT 
    stc.[Id] AS TestCaseId,
    stc.[Name] AS TestCaseName,
    stc.[ServiceRequestFileId],
    stc.[IsActive] AS TestCaseIsActive,
    stc.[RecordVersion] AS TestCaseVersion,
    stc.[CreatedAt] AS TestCaseCreatedAt,
    stc.[CreatedBy] AS TestCaseCreatedBy,
    stc.[LastUpdatedAt] AS TestCaseLastUpdatedAt,
    stc.[LastUpdatedBy] AS TestCaseLastUpdatedBy,
    
    -- Request File details
    srf.[Name] AS RequestFileName,
    srf.[FileFormat] AS RequestFileFormat,
    srf.[IsBaseSnapshot] AS RequestIsBase,
    srf.[UncompressedSizeBytes] AS RequestSize,
    
    -- Linked Test Suites (JSON array)
    (
        SELECT 
            sts.[Id] AS TestSuiteId,
            sts.[Name] AS SuiteName,
            l.[ExecutionOrder],
            l.[IsActive] AS LinkIsActive
        FROM [dbo].[ServiceTestSuiteTestCaseLinks] l
        INNER JOIN [dbo].[ServiceTestSuites] sts ON l.[ServiceTestSuiteId] = sts.[Id]
        WHERE l.[ServiceTestCaseId] = stc.[Id]
          AND sts.[IsActive] = 1
        FOR JSON AUTO
    ) AS LinkedSuites,
    
    -- Count of linked suites
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceTestSuiteTestCaseLinks] l
        WHERE l.[ServiceTestCaseId] = stc.[Id]
    ) AS SuiteCount,
    
    -- Linked Rule Sets (JSON array)
    (
        SELECT 
            rs.[Id] AS RuleSetId,
            rs.[WorkflowName],
            rco.[ContextName] AS OutputContext
        FROM [dbo].[ServiceTestCaseRuleSetLinks] rl
        INNER JOIN [dbo].[RuleSets] rs ON rl.[RuleSetId] = rs.[Id]
        LEFT JOIN [dbo].[RuleContextObjects] rco ON rs.[OutputTypeId] = rco.[Id]
        WHERE rl.[ServiceTestCaseId] = stc.[Id]
          AND rl.[IsActive] = 1
        FOR JSON AUTO
    ) AS LinkedRuleSets,
    
    -- Count of linked rule sets
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceTestCaseRuleSetLinks] rl
        WHERE rl.[ServiceTestCaseId] = stc.[Id]
          AND rl.[IsActive] = 1
    ) AS RuleSetCount,
    
    -- Last execution result
    (
        SELECT TOP 1
            l.[ExecutionStatus],
            l.[HttpStatusCode],
            l.[HttpRequestDurationMs],
            l.[ExecutedAt]
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        WHERE l.[ServiceTestCaseId] = stc.[Id]
        ORDER BY l.[ExecutedAt] DESC
        FOR JSON AUTO
    ) AS LastExecution

FROM [dbo].[ServiceTestCases] stc
LEFT JOIN [dbo].[ServiceRequestFiles] srf ON stc.[ServiceRequestFileId] = srf.[Id];
GO