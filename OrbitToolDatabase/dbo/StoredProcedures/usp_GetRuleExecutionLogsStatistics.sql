/*
    Stored Procedure: usp_GetRuleExecutionLogsStatistics
    Description: Gets execution statistics for a rule set.
*/
CREATE PROCEDURE [dbo].[usp_GetRuleExecutionLogsStatistics]
    @RuleSetId INT,
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = DATEADD(DAY, -@DaysBack, GETDATE());

    SELECT 
        @RuleSetId AS RuleSetId,
        rs.[WorkflowName],
        
    -- Overall statistics (ISNULL defaults keep the row present for zero executions)
    COUNT(rel.[Id]) AS TotalExecutions,
    ISNULL(SUM(CASE WHEN rel.[IsSuccess] = 1 THEN 1 ELSE 0 END), 0) AS SuccessfulExecutions,
    ISNULL(SUM(CASE WHEN rel.[IsSuccess] = 0 THEN 1 ELSE 0 END), 0) AS FailedExecutions,
    AVG(rel.[ExecutionTimeMs]) AS AvgExecutionTimeMs,
    MIN(rel.[ExecutionTimeMs]) AS MinExecutionTimeMs,
    MAX(rel.[ExecutionTimeMs]) AS MaxExecutionTimeMs,
    
    -- Size statistics
    AVG(rel.[InputUncompressedSizeBytes]) AS AvgInputSize,
    AVG(rel.[OutputUncompressedSizeBytes]) AS AvgOutputSize,
    
    -- Success rate
    CASE 
        WHEN COUNT(rel.[Id]) > 0 THEN
            CAST((SUM(CASE WHEN rel.[IsSuccess] = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(rel.[Id]) AS DECIMAL(10,2))
        ELSE 0
    END AS SuccessRate,
        
        -- Daily breakdown
        (
            SELECT 
                CAST([ExecutedAt] AS DATE) AS ExecutionDate,
                COUNT(*) AS DailyExecutions,
                SUM(CASE WHEN [IsSuccess] = 1 THEN 1 ELSE 0 END) AS DailySuccesses,
                AVG([ExecutionTimeMs]) AS DailyAvgTime
            FROM [dbo].[RuleExecutionLogs] rel2
            WHERE rel2.[RuleSetId] = @RuleSetId
              AND rel2.[ExecutedAt] >= @StartDate
            GROUP BY CAST([ExecutedAt] AS DATE)
            ORDER BY ExecutionDate DESC
            FOR JSON AUTO
        ) AS DailyBreakdown,
        
        -- Recent executions (last 5)
        (
            SELECT TOP 5
                [Id],
                [IsSuccess],
                [ExecutionTimeMs],
                [ExecutedAt],
                [ExecutedBy]
            FROM [dbo].[RuleExecutionLogs] rel2
            WHERE rel2.[RuleSetId] = @RuleSetId
            ORDER BY rel2.[ExecutedAt] DESC
            FOR JSON AUTO
        ) AS RecentExecutions

    FROM [dbo].[RuleSets] rs
    LEFT JOIN [dbo].[RuleExecutionLogs] rel 
        ON rel.[RuleSetId] = rs.[Id]
       AND rel.[ExecutedAt] >= @StartDate
    WHERE rs.[Id] = @RuleSetId
    GROUP BY rs.[WorkflowName];
END;
GO