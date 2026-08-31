/*
    Stored Procedure: usp_GetRuleExecutionStatistics
    Description: Gets execution statistics for a rule set.
*/
CREATE PROCEDURE [dbo].[usp_GetRuleExecutionStatistics]
    @RuleSetId INT,
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = DATEADD(DAY, -@DaysBack, GETDATE());

    SELECT 
        @RuleSetId AS RuleSetId,
        rs.[WorkflowName],
        
        -- Overall statistics
        COUNT(*) AS TotalExecutions,
        SUM(CASE WHEN [IsSuccess] = 1 THEN 1 ELSE 0 END) AS SuccessfulExecutions,
        SUM(CASE WHEN [IsSuccess] = 0 THEN 1 ELSE 0 END) AS FailedExecutions,
        AVG([ExecutionTimeMs]) AS AvgExecutionTimeMs,
        MIN([ExecutionTimeMs]) AS MinExecutionTimeMs,
        MAX([ExecutionTimeMs]) AS MaxExecutionTimeMs,
        
        -- Size statistics
        AVG([InputUncompressedSizeBytes]) AS AvgInputSize,
        AVG([OutputUncompressedSizeBytes]) AS AvgOutputSize,
        
        -- Success rate
        CASE 
            WHEN COUNT(*) > 0 THEN
                CAST((SUM(CASE WHEN [IsSuccess] = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS DECIMAL(10,2))
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

    FROM [dbo].[RuleExecutionLogs] rel
    INNER JOIN [dbo].[RuleSets] rs ON rel.[RuleSetId] = rs.[Id]
    WHERE rel.[RuleSetId] = @RuleSetId
      AND rel.[ExecutedAt] >= @StartDate
    GROUP BY rs.[WorkflowName];
END;
GO