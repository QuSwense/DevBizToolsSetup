/*
    View: v_RuleContextObjectsWithUsage
    Description: Context objects with usage statistics.
*/
CREATE VIEW [dbo].[v_RuleContextObjectsWithUsage]
AS
SELECT 
    rco.[Id] AS ContextObjectId,
    rco.[ContextName],
    rco.[RuleTypeId],
    rco.[Description],
    rco.[IsActive],
    rco.[CreatedDate],
    rco.[CreatedBy],
    rco.[LastUpdatedDate],
    rco.[LastUpdatedBy],
    
    -- Usage as Output Type
    (
        SELECT COUNT(*)
        FROM [dbo].[RuleSets] rs
        WHERE rs.[OutputTypeId] = rco.[Id]
    ) AS UsedAsOutputCount,
    
    -- Usage as Linked Context
    (
        SELECT COUNT(*)
        FROM [dbo].[RuleSetContextObjectLinks] rl
        WHERE rl.[RuleContextObjectId] = rco.[Id]
    ) AS UsedAsContextCount,
    
    -- Total Usage
    (
        SELECT COUNT(*)
        FROM [dbo].[RuleSets] rs
        WHERE rs.[OutputTypeId] = rco.[Id]
    ) + (
        SELECT COUNT(*)
        FROM [dbo].[RuleSetContextObjectLinks] rl
        WHERE rl.[RuleContextObjectId] = rco.[Id]
    ) AS TotalUsage,
    
    -- Rule sets using this as output
    (
        SELECT 
            STRING_AGG(rs.[WorkflowName], ', ')
        FROM [dbo].[RuleSets] rs
        WHERE rs.[OutputTypeId] = rco.[Id]
    ) AS OutputRuleSets,
    
    -- Rule sets linked to this context
    (
        SELECT 
            STRING_AGG(rs.[WorkflowName], ', ')
        FROM [dbo].[RuleSetContextObjectLinks] rl
        INNER JOIN [dbo].[RuleSets] rs ON rl.[RuleSetId] = rs.[Id]
        WHERE rl.[RuleContextObjectId] = rco.[Id]
    ) AS LinkedRuleSets,
    
    -- Age
    DATEDIFF(DAY, rco.[CreatedDate], GETDATE()) AS AgeDays

FROM [dbo].[RuleContextObjects] rco;
GO