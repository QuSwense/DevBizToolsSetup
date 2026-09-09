/*
    Stored Procedure: usp_UpdateDirectExecutionAuditResponseFileLinkStatus
    Description: Updates the execution status, HTTP response details, and timing for a response file link.
*/
CREATE PROCEDURE [dbo].[usp_UpdateDirectExecutionAuditResponseFileLinkStatus]
    @LinkId INT,
    @ExecutionStatus NVARCHAR(50),
    @HttpStatusCode INT = NULL,
    @HttpRequestDurationMs INT = NULL,
    @HttpContentType NVARCHAR(100) = NULL,
    @HttpRequestHeaders NVARCHAR(MAX) = NULL,
    @HttpResponseHeaders NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        -- Validate link exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[DirectExecutionAuditResponseFileLinks] WHERE [Id] = @LinkId)
        BEGIN
            RAISERROR('Response file link with Id %d not found.', 16, 1, @LinkId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update link record
        UPDATE [dbo].[DirectExecutionAuditResponseFileLinks]
        SET
            [ExecutionStatus] = @ExecutionStatus,
            [HttpStatusCode] = @HttpStatusCode,
            [HttpRequestDurationMs] = @HttpRequestDurationMs,
            [HttpContentType] = @HttpContentType,
            [HttpRequestHeaders] = @HttpRequestHeaders,
            [HttpResponseHeaders] = @HttpResponseHeaders,
            [ExecutionCompletedAt] = GETDATE()
        WHERE [Id] = @LinkId;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END;
GO