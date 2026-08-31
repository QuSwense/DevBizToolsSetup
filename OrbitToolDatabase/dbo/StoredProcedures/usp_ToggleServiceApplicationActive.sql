/*
    Stored Procedure: usp_ToggleServiceApplicationActive
    Description: Toggles the active status of a service application based on PublicId.
    Includes audit logging for the status change.
*/
CREATE PROCEDURE [dbo].[usp_ToggleServiceApplicationActive]
    @PublicId UNIQUEIDENTIFIER,
    @UserId NVARCHAR(20),
    @IsActive BIT
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
        -- Get the latest version by PublicId
        DECLARE @TargetId INT;
        DECLARE @CurrentRecordVersion VARCHAR(50);
        DECLARE @CurrentIsActive BIT;
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @ActivityId BIGINT;
        DECLARE @LogMessage NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the latest version (active or inactive) 
        SELECT TOP 1
            @TargetId = [Id],
            @CurrentRecordVersion = [RecordVersion],
            @CurrentIsActive = [IsActive],
            @ServiceName = [Name]
        FROM [dbo].[ServiceApplications] WITH (UPDLOCK, HOLDLOCK)
        WHERE [PublicId] = @PublicId
        ORDER BY [Id] DESC;

        DECLARE @PublicIdText VARCHAR(36) = CONVERT(varchar(36), @PublicId);
        IF @TargetId IS NULL
        BEGIN
            RAISERROR('Service application with PublicId %s not found.', 16, 1, @PublicIdText);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- If trying to set to same state, just return
        IF @CurrentIsActive = @IsActive
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;
            RETURN;
        END

        -- For IsActive changes, we do in-place update (no new version)
        UPDATE [dbo].[ServiceApplications]
        SET 
            [IsActive] = @IsActive,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @TargetId;

        -- Prepare audit log
        SET @LogMessage = 'Service status changed from ' + 
            CASE WHEN @CurrentIsActive = 1 THEN 'Active' ELSE 'Inactive' END + 
            ' to ' + 
            CASE WHEN @IsActive = 1 THEN 'Active' ELSE 'Inactive' END;

        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'StatusToggle' AS ChangeType,
                @PublicId AS ServiceId,
                @ServiceName AS ServiceName,
                @CurrentIsActive AS OldIsActive,
                @IsActive AS NewIsActive,
                @LogMessage AS Message
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Insert audit log
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceApplicationToggle',
            @ActionType = 'StatusToggle',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @PublicId,
            @Notes = @LogMessage,
            @ActivityId = @ActivityId OUTPUT;

        -- Return the updated record
        SELECT 
            [PublicId],
            [Id] AS InternalId,
            [Name],
            [ServiceType],
            [BaseUrl],
            [DefinitionType],
            [DefinitionRelativeUrl],
            [HealthcheckRelativeUrl],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @TargetId;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO