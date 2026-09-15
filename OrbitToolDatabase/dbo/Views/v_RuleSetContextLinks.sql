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
    
    -- Rule Set details
    rs.[PublicId] AS RuleSetPublicId,
    rs.[WorkflowName],
    rs.[IsActive] AS RuleSetIsActive,
    rs.[Description] AS RuleSetDescription,
    
    -- Context Object details
    rco.[PublicId] AS ContextObjectPublicId,
    rco.[ContextName],
    rco.[RuleTypeId] AS ContextRuleTypeId,
    rco.[Description] AS ContextDescription,
    rco.[IsActive] AS ContextIsActive,
    
    -- User details
    CONCAT(u_created.[FirstName], ' ', u_created.[LastName]) AS CreatedByFullName

FROM [dbo].[RuleSetContextObjectLinks] rl
INNER JOIN [dbo].[RuleSets] rs ON rl.[RuleSetId] = rs.[Id]
INNER JOIN [dbo].[RuleContextObjects] rco ON rl.[RuleContextObjectId] = rco.[Id]
LEFT JOIN [dbo].[Users] u_created ON rl.[CreatedBy] = u_created.[UserId];
GO