/*
    Stored Procedure: usp_InsertUserActivity
    Description: Inserts a user activity log entry for auditing and analytics purposes.
    
    Parameters:
        @UserId NVARCHAR(20) - The ID of the user performing the activity
        @ActivityType NVARCHAR(100) - The type of activity (e.g., 'ServiceUpdate', 'ServiceToggle')
        @ActionType NVARCHAR(50) - Optional granular action type (e.g., 'Update', 'Create', 'Toggle')
        @FeatureActivitiesJson NVARCHAR(MAX) - JSON containing detailed activity information
        @RelatedEntityType NVARCHAR(50) - Optional: Type of entity affected (e.g., 'ServiceApplication')
        @RelatedEntityId UNIQUEIDENTIFIER - Optional: PublicId of the affected entity
        @Notes NVARCHAR(MAX) - Optional: Additional notes about the activity
    
    Returns:
        @ActivityId BIGINT - The ID of the newly created activity record
*/
CREATE PROCEDURE [dbo].[usp_InsertUserActivity]
    @UserId NVARCHAR(20),
    @ActivityType NVARCHAR(100),
    @ActionType NVARCHAR(50) = NULL,
    @FeatureActivitiesJson NVARCHAR(MAX) = NULL,
    @RelatedEntityType NVARCHAR(50) = NULL,
    @RelatedEntityId UNIQUEIDENTIFIER = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ActivityId BIGINT OUTPUT
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
        -- Build the JSON if not provided but we have related entity info
        IF @FeatureActivitiesJson IS NULL AND (@RelatedEntityType IS NOT NULL OR @RelatedEntityId IS NOT NULL)
        BEGIN
            SET @FeatureActivitiesJson = JSON_MODIFY(
                JSON_MODIFY(
                    '{}',
                    '$.RelatedEntityType', @RelatedEntityType
                ),
                '$.RelatedEntityId', CAST(@RelatedEntityId AS NVARCHAR(50))
            );
            
            IF @Notes IS NOT NULL
            BEGIN
                SET @FeatureActivitiesJson = JSON_MODIFY(
                    @FeatureActivitiesJson,
                    '$.Notes', @Notes
                );
            END
        END

        -- Insert the activity
        INSERT INTO [dbo].[UserActivities] (
            [UserId],
            [ActivityType],
            [ActionType],
            [FeatureActivitiesJson],
            [Timestamp]
        )
        VALUES (
            @UserId,
            @ActivityType,
            @ActionType,
            @FeatureActivitiesJson,
            GETDATE()
        );

        -- Get the inserted ID
        SET @ActivityId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the activity ID
        SELECT @ActivityId AS ActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO