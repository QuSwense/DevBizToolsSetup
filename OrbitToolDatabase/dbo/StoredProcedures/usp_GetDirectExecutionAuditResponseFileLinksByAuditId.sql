/*
    Stored Procedure: usp_GetDirectExecutionAuditResponseFileLinksByAuditId
    Description: Gets all response file links for a given direct execution audit, ordered by execution order.
*/
CREATE PROCEDURE [dbo].[usp_GetDirectExecutionAuditResponseFileLinksByAuditId]
    @DirectExecutionAuditId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id],
        [DirectExecutionAuditId],
        [ServiceRequestFileId],
        [ExecutionOrder],
        [ExecutionStatus],
        [HttpStatusCode],
        [HttpRequestDurationMs],
        [HttpContentType],
        [HttpRequestHeaders],
        [HttpResponseHeaders],
        [ExecutedAt],
        [ExecutionCompletedAt]
    FROM [dbo].[DirectExecutionAuditResponseFileLinks]
    WHERE [DirectExecutionAuditId] = @DirectExecutionAuditId
    ORDER BY [ExecutionOrder];
END;
GO