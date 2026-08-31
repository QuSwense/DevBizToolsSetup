/*
    Stored Procedure: usp_GetRuleSetsByContext
    Description: Gets all rule sets linked to a specific context object.
*/
CREATE PROCEDURE [dbo].[usp_GetRuleSetsByContext]
    @ContextName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

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
        rco.[ContextName] AS LinkedContextName,
        rco.[RuleTypeId] AS ContextRuleTypeId
    FROM [dbo].[RuleSets] rs
    INNER JOIN [dbo].[RuleSetContextObjectLinks] rl ON rs.[Id] = rl.[RuleSetId]
    INNER JOIN [dbo].[RuleContextObjects] rco ON rl.[RuleContextObjectId] = rco.[Id]
    WHERE rco.[ContextName] = @ContextName
      AND rs.[IsActive] = 1
      AND rco.[IsActive] = 1
    ORDER BY rs.[WorkflowName];
END;
GO