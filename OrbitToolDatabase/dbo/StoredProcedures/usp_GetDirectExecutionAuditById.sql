/*
    Stored Procedure: usp_GetDirectExecutionAuditById
    Description: Gets a direct execution audit by its primary key identifier.
*/
CREATE PROCEDURE [dbo].[usp_GetDirectExecutionAuditById]
    @AuditId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id],
        [Name],
        [ExecutedAt],
        [ExecutionStatus],
        [ExecutionCompletedAt],
        [ExecutionDetails],
        [ExecutedBy]
    FROM [dbo].[DirectExecutionAudit]
    WHERE [Id] = @AuditId;
END;
GO