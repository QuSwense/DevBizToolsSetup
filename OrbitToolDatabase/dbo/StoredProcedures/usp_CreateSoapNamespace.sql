/*
    Stored Procedure: usp_CreateSoapNamespace
    Description: Creates a new SOAP namespace entry for a service operation schema with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateSoapNamespace]
    @ServiceOperationSchemaId INT,
    @CompressedContent VARBINARY(MAX),
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
    @UserId NVARCHAR(20) = NULL
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
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedHash VARCHAR(64);
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate the schema exists and get related info
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceOperationSchemas] sos
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE sos.[Id] = @ServiceOperationSchemaId;

        IF @OperationName IS NULL
        BEGIN
            RAISERROR('Service operation schema with Id %d not found.', 16, 1, @ServiceOperationSchemaId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate hash if not provided
        IF @ContentHash IS NULL AND @CompressedContent IS NOT NULL
        BEGIN
            SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ContentHash;
        END

        -- Calculate initial version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[SoapNamespaces] (
            [ServiceOperationSchemaId],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @ServiceOperationSchemaId,
            @CompressedContent,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @CalculatedHash,
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('SOAP namespace created for operation: ', @OperationName, 
                           ' (Service: ', @ServiceName, ', Size: ', 
                           ISNULL(CAST(@UncompressedSizeBytes AS NVARCHAR(20)), 'unknown'), ' bytes)');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceOperationSchemaId AS SchemaId,
                @OperationName AS OperationName,
                @ServiceName AS ServiceName,
                @ServiceAppPublicId AS ServiceId,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedHash AS ContentHash,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'SoapNamespaceCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS NamespaceId,
            [ServiceOperationSchemaId],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[SoapNamespaces]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating SOAP namespace: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO