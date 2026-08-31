/*
    View: v_RuleSetsWithDetails
    Description: Comprehensive view of rule sets with context object details.
*/
CREATE VIEW [dbo].[v_RuleSetsWithDetails]
AS
SELECT 
    rs.[Id] AS RuleSetId,
    rs.[WorkflowName],
    rs.[RuleContent],
    rs.[OutputTypeId],
    rs.[IsActive],
    rs.[Description],
    rs.[RecordVersion],
    rs.[CreatedAt],
    rs.[CreatedBy],
    rs.[LastUpdatedAt],
    rs.[LastUpdatedBy],
    
    -- Output Context details
    rco.[ContextName] AS OutputContextName,
    rco.[RuleTypeId] AS OutputRuleTypeId,
    rco.[Description] AS OutputContextDescription,
    
    -- Linked Context Objects (JSON array)
    (
        SELECT 
            rco2.[Id] AS ContextObjectId,
            rco2.[ContextName],
            rco2.[RuleTypeId]
        FROM [dbo].[RuleSetContextObjectLinks] rl
        INNER JOIN [dbo].[RuleContextObjects] rco2 ON rl.[RuleContextObjectId] = rco2.[Id]
        WHERE rl.[RuleSetId] = rs.[Id]
        FOR JSON AUTO
    ) AS LinkedContextObjects,
    
    -- Count of linked contexts
    (
        SELECT COUNT(*)
        FROM [dbo].[RuleSetContextObjectLinks] rl
        WHERE rl.[RuleSetId] = rs.[Id]
    ) AS LinkedContextCount,
    
    -- Last execution details
    (
        SELECT TOP 1
            [IsSuccess],
            [ExecutionTimeMs],
            [ExecutedAt],
            [ExecutedBy]
        FROM [dbo].[RuleExecutionLogs] rel
        WHERE rel.[RuleSetId] = rs.[Id]
        ORDER BY rel.[ExecutedAt] DESC
        FOR JSON AUTO
    ) AS LastExecution,
    
    -- Total execution count
    (
        SELECT COUNT(*)
        FROM [dbo].[RuleExecutionLogs] rel
        WHERE rel.[RuleSetId] = rs.[Id]
    ) AS TotalExecutions,
    
    -- Success rate
    CASE 
        WHEN (
            SELECT COUNT(*)
            FROM [dbo].[RuleExecutionLogs] rel
            WHERE rel.[RuleSetId] = rs.[Id]
        ) > 0 THEN
            CAST(
                (SELECT COUNT(*) * 100.0
                 FROM [dbo].[RuleExecutionLogs] rel
                 WHERE rel.[RuleSetId] = rs.[Id]
                   AND rel.[IsSuccess] = 1) / 
                (SELECT COUNT(*)
                 FROM [dbo].[RuleExecutionLogs] rel
                 WHERE rel.[RuleSetId] = rs.[Id])
                AS DECIMAL(10,2)
            )
        ELSE NULL
    END AS SuccessRate

FROM [dbo].[RuleSets] rs
LEFT JOIN [dbo].[RuleContextObjects] rco ON rs.[OutputTypeId] = rco.[Id];
GO