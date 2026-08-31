/*
    View: v_RuleSetContextLinks
    Description: View of rule set to context object links.
*/
CREATE VIEW [dbo].[v_RuleSetContextLinks]
AS
SELECT 
    rl.[Id] AS LinkId,
    rl.[RuleSetId],
    rl.[RuleContextObjectId],
    rl.[CreatedAt],
    rl.[CreatedBy],
    rl.[LastUpdatedAt],
    rl.[LastUpdatedBy],
    
    -- Rule Set details
    rs.[WorkflowName],
    rs.[IsActive] AS RuleSetIsActive,
    rs.[Description] AS RuleSetDescription,
    
    -- Context Object details
    rco.[ContextName],
    rco.[RuleTypeId] AS ContextRuleTypeId,
    rco.[Description] AS ContextDescription,
    rco.[IsActive] AS ContextIsActive,
    
    -- User details
    CONCAT(u_created.[FirstName], ' ', u_created.[LastName]) AS CreatedByFullName,
    CONCAT(u_updated.[FirstName], ' ', u_updated.[LastName]) AS LastUpdatedByFullName

FROM [dbo].[RuleSetContextObjectLinks] rl
INNER JOIN [dbo].[RuleSets] rs ON rl.[RuleSetId] = rs.[Id]
INNER JOIN [dbo].[RuleContextObjects] rco ON rl.[RuleContextObjectId] = rco.[Id]
LEFT JOIN [dbo].[Users] u_created ON rl.[CreatedBy] = u_created.[UserId]
LEFT JOIN [dbo].[Users] u_updated ON rl.[LastUpdatedBy] = u_updated.[UserId];
GO