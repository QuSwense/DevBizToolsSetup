/*
    Stored Procedure: usp_GetTestSuiteExecutionSummary
    Description: Gets execution summary statistics for a test suite.
*/
CREATE PROCEDURE [dbo].[usp_GetTestSuiteExecutionSummary]
    @ServiceTestSuiteId INT,
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = DATEADD(DAY, -@DaysBack, GETDATE());

    SELECT 
        @ServiceTestSuiteId AS TestSuiteId,
        sts.[Name] AS SuiteName,
        
        -- Execution counts
        COUNT(*) AS TotalExecutions,
        SUM(CASE WHEN [ExecutionStatus] = 'Completed' THEN 1 ELSE 0 END) AS SuccessfulExecutions,
        SUM(CASE WHEN [ExecutionStatus] = 'Failed' THEN 1 ELSE 0 END) AS FailedExecutions,
        
        -- Success rate
        CASE 
            WHEN COUNT(*) > 0 THEN
                CAST((SUM(CASE WHEN [ExecutionStatus] = 'Completed' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS DECIMAL(10,2))
            ELSE 0
        END AS SuccessRate,
        
        -- Duration stats
        AVG(DATEDIFF(SECOND, [ExecutedAt], ISNULL([ExecutionCompletedAt], [ExecutedAt]))) AS AvgDurationSeconds,
        MIN(DATEDIFF(SECOND, [ExecutedAt], ISNULL([ExecutionCompletedAt], [ExecutedAt]))) AS MinDurationSeconds,
        MAX(DATEDIFF(SECOND, [ExecutedAt], ISNULL([ExecutionCompletedAt], [ExecutedAt]))) AS MaxDurationSeconds,
        
        -- Test case execution stats
        (
            SELECT 
                COUNT(DISTINCT l.[ServiceTestCaseId]) AS DistinctTestCases,
                COUNT(*) AS TotalTestCaseExecutions,
                SUM(CASE WHEN l.[ExecutionStatus] = 'Completed' THEN 1 ELSE 0 END) AS SuccessfulTestCaseExecutions,
                SUM(CASE WHEN l.[ExecutionStatus] = 'Failed' THEN 1 ELSE 0 END) AS FailedTestCaseExecutions
            FROM [dbo].[ServiceTestSuiteExecutionAudits] a2
            INNER JOIN [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l ON a2.[Id] = l.[ServiceTestSuiteExecutionAuditId]
            WHERE a2.[ServiceTestSuiteId] = @ServiceTestSuiteId
              AND a2.[ExecutedAt] >= @StartDate
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS TestCaseStats,
        
        -- Daily breakdown (JSON)
        (
            SELECT 
                CAST([ExecutedAt] AS DATE) AS ExecutionDate,
                COUNT(*) AS DailyExecutions,
                SUM(CASE WHEN [ExecutionStatus] = 'Completed' THEN 1 ELSE 0 END) AS DailySuccesses,
                COUNT(DISTINCT [ExecutedBy]) AS UniqueExecutors
            FROM [dbo].[ServiceTestSuiteExecutionAudits] a2
            WHERE a2.[ServiceTestSuiteId] = @ServiceTestSuiteId
              AND a2.[ExecutedAt] >= @StartDate
            GROUP BY CAST([ExecutedAt] AS DATE)
            ORDER BY ExecutionDate DESC
            FOR JSON AUTO
        ) AS DailyBreakdown,
        
        -- Recent executions (JSON)
        (
            SELECT TOP 10
                [Id] AS AuditId,
                [ExecutedAt],
                [ExecutionStatus],
                [ExecutedBy],
                DATEDIFF(SECOND, [ExecutedAt], ISNULL([ExecutionCompletedAt], [ExecutedAt])) AS DurationSeconds
            FROM [dbo].[ServiceTestSuiteExecutionAudits] a2
            WHERE a2.[ServiceTestSuiteId] = @ServiceTestSuiteId
            ORDER BY a2.[ExecutedAt] DESC
            FOR JSON AUTO
        ) AS RecentExecutions

    FROM [dbo].[ServiceTestSuiteExecutionAudits] a
    INNER JOIN [dbo].[ServiceTestSuites] sts ON a.[ServiceTestSuiteId] = sts.[Id]
    WHERE a.[ServiceTestSuiteId] = @ServiceTestSuiteId
      AND a.[ExecutedAt] >= @StartDate
    GROUP BY sts.[Name];
END;
GO