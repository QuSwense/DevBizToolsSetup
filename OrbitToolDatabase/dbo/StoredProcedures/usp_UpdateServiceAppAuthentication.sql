/*
    Stored Procedure: usp_UpdateServiceAppAuthentication
    Description: Updates an existing ServiceAppAuthentication record using PublicId. 
    It manages RecordVersion for optimistic concurrency control and ensures audit fields are updated accordingly.
    Includes comprehensive audit logging for all changes.
    
    Logic:
    - Accepts PublicId (GUID) instead of internal Id for security
    - Fetches the current RecordVersion to ensure update is based on latest version
    - Resolves audit user with proper fallback chain
    - Recalculates RecordVersion using fn_CalculateVersion
    - Handles nested transactions gracefully
    - Logs all changes to UserActivities table
    - Returns updated record information with audit ID
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceAppAuthentication]
    @PublicId UNIQUEIDENTIFIER,
    @Name NVARCHAR(200) = NULL,
    @AuthenticationType VARCHAR(50) = NULL,
    @EncryptionAlgorithmType VARCHAR(50) = NULL,
    @EncryptedJson NVARCHAR(MAX) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @ActivityNotes NVARCHAR(MAX) = NULL  -- Optional: notes for audit log
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Manage nested transactions gracefully (.NET compatibility)
    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        -- 2. Declare variables
        DECLARE @InternalId INT;
        DECLARE @CurrentRecordVersion VARCHAR(50);
        DECLARE @CurrentIsActive BIT;
        DECLARE @ExistingName NVARCHAR(200);
        DECLARE @ExistingAuthenticationType VARCHAR(50);
        DECLARE @ExistingEncryptionAlgorithmType VARCHAR(50);
        DECLARE @ExistingEncryptedJson NVARCHAR(MAX);
        DECLARE @ExistingCreatedAt DATETIME;
        DECLARE @ExistingCreatedBy NVARCHAR(20);
        DECLARE @ExistingLastUpdatedBy NVARCHAR(20);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NameChanged BIT = 0;
        DECLARE @AuthTypeChanged BIT = 0;
        DECLARE @EncryptionChanged BIT = 0;
        DECLARE @JsonChanged BIT = 0;
        DECLARE @OldValueJson NVARCHAR(MAX);
        DECLARE @NewValueJson NVARCHAR(MAX);
        DECLARE @ActivityId BIGINT;
        DECLARE @LogMessage NVARCHAR(MAX);

        -- 3. Fetch the current record with locking
        SELECT TOP 1
            @InternalId = [Id],
            @CurrentRecordVersion = [RecordVersion],
            @CurrentIsActive = [IsActive],
            @ExistingName = [Name],
            @ExistingAuthenticationType = [AuthenticationType],
            @ExistingEncryptionAlgorithmType = [EncryptionAlgorithmType],
            @ExistingEncryptedJson = [EncryptedJson],
            @ExistingCreatedAt = [CreatedAt],
            @ExistingCreatedBy = [CreatedBy],
            @ExistingLastUpdatedBy = [LastUpdatedBy]
        FROM [dbo].[ServiceAppAuthentications] WITH (UPDLOCK, HOLDLOCK)
        WHERE [PublicId] = @PublicId
        ORDER BY [Id] DESC;

        -- 4. Check if record exists
        DECLARE @PublicIdText VARCHAR(36) = CONVERT(varchar(36), @PublicId);
        IF @InternalId IS NULL
        BEGIN
            RAISERROR('ServiceAppAuthentication record with PublicId %s not found.', 16, 1, @PublicIdText);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 5. Check if record is active (can only update active records)
        IF @CurrentIsActive = 0
        BEGIN
            RAISERROR('Cannot update inactive authentication configuration. Please reactivate first.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 6. Resolve the audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- 7. Build old values JSON for audit
        SET @OldValueJson = (
            SELECT 
                @ExistingName AS Name,
                @ExistingAuthenticationType AS AuthenticationType,
                @ExistingEncryptionAlgorithmType AS EncryptionAlgorithmType,
                @CurrentRecordVersion AS RecordVersion,
                @CurrentIsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- 8. Check for duplicate Name if Name is being updated
        IF @Name IS NOT NULL AND @Name <> @ExistingName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceAppAuthentications] 
                WHERE [Name] = @Name 
                  AND [PublicId] != @PublicId
                  AND [IsActive] = 1
            )
            BEGIN
                RAISERROR('An active authentication configuration with the name "%s" already exists.', 16, 1, @Name);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
            SET @NameChanged = 1;
        END

        -- 9. Determine what changed
        IF @AuthenticationType IS NOT NULL AND @AuthenticationType <> @ExistingAuthenticationType
            SET @AuthTypeChanged = 1;

        IF @EncryptionAlgorithmType IS NOT NULL AND @EncryptionAlgorithmType <> @ExistingEncryptionAlgorithmType
            SET @EncryptionChanged = 1;

        IF @EncryptedJson IS NOT NULL AND @EncryptedJson <> @ExistingEncryptedJson
            SET @JsonChanged = 1;

        -- 10. If no changes detected, return existing record
        IF @NameChanged = 0 AND @AuthTypeChanged = 0 AND @EncryptionChanged = 0 AND @JsonChanged = 0
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;
            
            -- Return existing record
            SELECT 
                [PublicId],
                [Id] AS InternalId,
                [Name],
                [AuthenticationType],
                [EncryptionAlgorithmType],
                [RecordVersion],
                [IsActive],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy],
                NULL AS AuditActivityId
            FROM [dbo].[ServiceAppAuthentications]
            WHERE [Id] = @InternalId;
            
            RETURN;
        END

        -- 11. Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@CurrentRecordVersion);

        -- 12. Perform the update
        UPDATE [dbo].[ServiceAppAuthentications]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [AuthenticationType] = ISNULL(@AuthenticationType, [AuthenticationType]),
            [EncryptionAlgorithmType] = ISNULL(@EncryptionAlgorithmType, [EncryptionAlgorithmType]),
            [EncryptedJson] = ISNULL(@EncryptedJson, [EncryptedJson]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @InternalId;

        -- 13. Build new values JSON for audit
        SET @NewValueJson = (
            SELECT 
                ISNULL(@Name, @ExistingName) AS Name,
                ISNULL(@AuthenticationType, @ExistingAuthenticationType) AS AuthenticationType,
                ISNULL(@EncryptionAlgorithmType, @ExistingEncryptionAlgorithmType) AS EncryptionAlgorithmType,
                @NewRecordVersion AS NewRecordVersion,
                @CurrentRecordVersion AS OldRecordVersion,
                @CurrentIsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- 14. Prepare audit log message
        SET @LogMessage = 'Authentication configuration updated. New version: ' + @NewRecordVersion;
        IF @NameChanged = 1
            SET @LogMessage = @LogMessage + '. Name changed from "' + @ExistingName + '" to "' + ISNULL(@Name, @ExistingName) + '"';
        IF @AuthTypeChanged = 1
            SET @LogMessage = @LogMessage + '. Authentication type changed from "' + @ExistingAuthenticationType + '" to "' + ISNULL(@AuthenticationType, @ExistingAuthenticationType) + '"';
        IF @EncryptionChanged = 1
            SET @LogMessage = @LogMessage + '. Encryption algorithm changed from "' + ISNULL(@ExistingEncryptionAlgorithmType, 'None') + '" to "' + ISNULL(@EncryptionAlgorithmType, 'None') + '"';
        IF @JsonChanged = 1
            SET @LogMessage = @LogMessage + '. Credentials updated.';

        -- 15. Build feature JSON for audit
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'AuthConfigUpdate' AS ChangeType,
                @PublicId AS AuthConfigId,
                ISNULL(@Name, @ExistingName) AS AuthConfigName,
                @CurrentRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @LogMessage AS Message,
                @OldValueJson AS OldValues,
                @NewValueJson AS NewValues,
                @ActivityNotes AS Notes
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- 16. Insert audit log
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'AuthenticationConfigUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceAppAuthentication',
            @RelatedEntityId = @PublicId,
            @Notes = @LogMessage,
            @ActivityId = @ActivityId OUTPUT;

        -- 17. Return the updated record
        SELECT 
            [PublicId],
            [Id] AS InternalId,
            [Name],
            [AuthenticationType],
            [EncryptionAlgorithmType],
            [RecordVersion],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceAppAuthentications]
        WHERE [Id] = @InternalId;

        -- 18. Commit if this SP started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Rollback only if this SP opened the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Rethrow the error with additional context
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating authentication configuration: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO