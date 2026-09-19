/*
    Stored Procedure: usp_SaveServiceDefinitionWithOperations

    Single-click sync procedure.

    Behaviour
    ---------
    1. Compares the incoming definition CompressedContent against the
       latest ServiceDefinitionSync for the application.
    2. Compares every supplied operation (by name) and its schema
       CompressedContent against the latest operation + latest schema.
    3. Also verifies that the set of OperationNames is identical
       (no new ops, no missing ops) and that key operation metadata
       (EndpointOrAction, HttpMethod, Description, IsActive) matches.

    If EVERYTHING matches:
        - Returns existing metadata
        - WasCreated = 0 / SaveResult = 'Existing'

    Otherwise:
        - Inserts a new ServiceDefinitionSync
        - Inserts a new ServiceOperation row for every supplied operation
        - Inserts a new ServiceOperationSchema for each of those operations
        - Returns the new metadata
        - WasCreated = 1 / SaveResult = 'Created'

    Result sets
    -----------
    1. Definition header + flag
    2. Operations (Id, name, …)
    3. Schemas   (Id, OperationId, …)
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveServiceDefinitionWithOperations]
    @ServiceApplicationId               INT,
    @DefinitionUrl                      NVARCHAR(1024) = NULL,
    @DefinitionCompressedContent        VARBINARY(MAX),
    @DefinitionUncompressedSizeBytes    BIGINT = NULL,
    @DefinitionCompressionAlgorithmType VARCHAR(50) = NULL,
    @Operations                         [dbo].[ServiceOperationSchemaInput] READONLY,
    @UserId                             NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LocalTranStarted BIT = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE
            @ResolvedUser               NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM'),
            @ExistingDefId              INT,
            @ExistingDefContent         VARBINARY(MAX),
            @IsContentIdentical         BIT = 0,
            @NewDefId                   INT,
            @OpCount                    INT,
            @MatchedOpCount             INT;

        /* ---------- Validation ---------- */
        IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceApplications] WHERE [Id] = @ServiceApplicationId)
            RAISERROR('Service application was not found.', 16, 1);

        IF @DefinitionCompressedContent IS NULL
            RAISERROR('Definition compressed content is required.', 16, 1);

        IF @DefinitionCompressionAlgorithmType IS NOT NULL
           AND @DefinitionCompressionAlgorithmType NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
            RAISERROR('Invalid DefinitionCompressionAlgorithmType.', 16, 1);

        IF EXISTS (
            SELECT 1 FROM @Operations
            WHERE [SchemaCompressionAlgorithmType] IS NOT NULL
              AND [SchemaCompressionAlgorithmType] NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
        )
            RAISERROR('Invalid SchemaCompressionAlgorithmType in one or more operations.', 16, 1);

        IF EXISTS (
            SELECT 1 FROM @Operations
            WHERE [HttpMethod] IS NOT NULL
              AND [HttpMethod] NOT IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
        )
            RAISERROR('Invalid HttpMethod in one or more operations.', 16, 1);

        IF EXISTS (
            SELECT 1 FROM @Operations
            WHERE NULLIF(LTRIM(RTRIM([OperationName])), '') IS NULL
        )
            RAISERROR('OperationName is required for every row.', 16, 1);

        IF EXISTS (
            SELECT [OperationName]
            FROM @Operations
            GROUP BY [OperationName]
            HAVING COUNT(*) > 1
        )
            RAISERROR('Duplicate OperationName values are not allowed.', 16, 1);

        SELECT @OpCount = COUNT(*) FROM @Operations;

        /* ---------- Load latest definition (locked) ---------- */
        SELECT TOP (1)
            @ExistingDefId      = [Id],
            @ExistingDefContent = [CompressedContent]
        FROM [dbo].[ServiceDefinitionSyncs] WITH (UPDLOCK, HOLDLOCK)
        WHERE [ServiceApplicationId] = @ServiceApplicationId
        ORDER BY [Id] DESC;

        /* ---------- Decide whether content is identical ---------- */
        IF @ExistingDefId IS NOT NULL
           AND @ExistingDefContent = @DefinitionCompressedContent
           AND @OpCount > 0
        BEGIN
            /*
                Definition binary matches.
                Now verify:
                  a) same set of OperationNames
                  b) each operation's metadata matches the latest version
                  c) each operation's latest schema binary matches
            */
            ;WITH LatestOps AS
            (
                SELECT
                    o.[Id]              AS ServiceOperationId,
                    o.[OperationName],
                    o.[EndpointOrAction],
                    o.[HttpMethod],
                    o.[Description],
                    o.[IsActive],
                    ROW_NUMBER() OVER
                    (
                        PARTITION BY o.[OperationName]
                        ORDER BY o.[Id] DESC
                    ) AS rn
                FROM [dbo].[ServiceOperations] o
                WHERE o.[ServiceApplicationId] = @ServiceApplicationId
            ),
            LatestSchemas AS
            (
                SELECT
                    s.[ServiceOperationId],
                    s.[CompressedContent],
                    ROW_NUMBER() OVER
                    (
                        PARTITION BY s.[ServiceOperationId]
                        ORDER BY s.[Id] DESC
                    ) AS rn
                FROM [dbo].[ServiceOperationSchemas] s
                INNER JOIN LatestOps lo
                    ON lo.ServiceOperationId = s.ServiceOperationId
                   AND lo.rn = 1
            )
            SELECT @MatchedOpCount = COUNT(*)
            FROM @Operations src
            INNER JOIN LatestOps lo
                ON lo.OperationName = src.OperationName
               AND lo.rn = 1
               AND ISNULL(lo.EndpointOrAction, N'')   = ISNULL(src.EndpointOrAction, N'')
               AND ISNULL(lo.HttpMethod, '')          = ISNULL(src.HttpMethod, '')
               AND ISNULL(lo.Description, N'')        = ISNULL(src.Description, N'')
               AND lo.IsActive                        = src.IsActive
            INNER JOIN LatestSchemas ls
                ON ls.ServiceOperationId = lo.ServiceOperationId
               AND ls.rn = 1
               AND ls.CompressedContent = src.SchemaCompressedContent;

            -- Also ensure the total number of latest operations equals the supplied set
            DECLARE @ExistingLatestOpCount INT;
            SELECT @ExistingLatestOpCount = COUNT(*)
            FROM (
                SELECT OperationName,
                       ROW_NUMBER() OVER (PARTITION BY OperationName ORDER BY Id DESC) AS rn
                FROM [dbo].[ServiceOperations]
                WHERE ServiceApplicationId = @ServiceApplicationId
            ) x
            WHERE x.rn = 1;

            IF @MatchedOpCount = @OpCount
               AND @ExistingLatestOpCount = @OpCount
            BEGIN
                SET @IsContentIdentical = 1;
            END
        END
        -- Special case: both sides have zero operations and definition matches
        ELSE IF @ExistingDefId IS NOT NULL
                AND @ExistingDefContent = @DefinitionCompressedContent
                AND @OpCount = 0
        BEGIN
            DECLARE @ExistingLatestOpCountZero INT;
            SELECT @ExistingLatestOpCountZero = COUNT(*)
            FROM (
                SELECT OperationName,
                       ROW_NUMBER() OVER (PARTITION BY OperationName ORDER BY Id DESC) AS rn
                FROM [dbo].[ServiceOperations]
                WHERE ServiceApplicationId = @ServiceApplicationId
            ) x
            WHERE x.rn = 1;

            IF @ExistingLatestOpCountZero = 0
                SET @IsContentIdentical = 1;
        END

        /* ---------- Branch: Existing vs Created ---------- */
        IF @IsContentIdentical = 1
        BEGIN
            -------------------------------------------------
            -- RETURN EXISTING METADATA
            -------------------------------------------------
            SET @NewDefId = @ExistingDefId;

            -- Result set 1: Definition
            SELECT
                d.[Id]                          AS ServiceDefinitionSyncId,
                d.[ServiceApplicationId],
                d.[DefinitionUrl],
                d.[UncompressedSizeBytes],
                d.[CompressionAlgorithmType],
                d.[RecordVersion],
                d.[CreatedAt],
                d.[CreatedBy],
                CAST(0 AS BIT)                  AS WasCreated,
                'Existing'                      AS SaveResult
            FROM [dbo].[ServiceDefinitionSyncs] d
            WHERE d.[Id] = @NewDefId;

            -- Result set 2: Latest operations
            SELECT
                lo.ServiceOperationId,
                lo.ServiceApplicationId,
                lo.ServiceDefinitionSyncId,
                lo.OperationName,
                lo.EndpointOrAction,
                lo.HttpMethod,
                lo.Description,
                lo.IsActive,
                lo.RecordVersion,
                lo.CreatedAt,
                lo.CreatedBy
            FROM [dbo].[vw_ServiceApplicationLatestOperations] lo
            WHERE lo.ServiceApplicationId = @ServiceApplicationId
            ORDER BY lo.OperationName;

            -- Result set 3: Latest schemas for those operations
            SELECT
                s.ServiceOperationSchemaId,
                s.ServiceOperationId,
                s.InputRootElementName,
                s.OutputRootElementName,
                s.TargetNamespace,
                s.UncompressedSizeBytes,
                s.CompressionAlgorithmType,
                s.RecordVersion,
                s.CreatedAt,
                s.CreatedBy
            FROM [dbo].[vw_ServiceOperationLatestSchema] s
            INNER JOIN [dbo].[vw_ServiceApplicationLatestOperations] o
                ON o.ServiceOperationId = s.ServiceOperationId
            WHERE o.ServiceApplicationId = @ServiceApplicationId
            ORDER BY o.OperationName;
        END
        ELSE
        BEGIN
            -------------------------------------------------
            -- INSERT NEW VERSIONS
            -------------------------------------------------

            -- 1. New definition
            INSERT INTO [dbo].[ServiceDefinitionSyncs]
            (
                [ServiceApplicationId],
                [DefinitionUrl],
                [CompressedContent],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [CreatedAt],
                [CreatedBy]
            )
            VALUES
            (
                @ServiceApplicationId,
                @DefinitionUrl,
                @DefinitionCompressedContent,
                @DefinitionUncompressedSizeBytes,
                @DefinitionCompressionAlgorithmType,
                GETDATE(),
                @ResolvedUser
            );

            SET @NewDefId = CONVERT(INT, SCOPE_IDENTITY());

            -- 2. New operations + schemas (set-based)
            DECLARE @InsertedOps TABLE
            (
                ServiceOperationId  INT NOT NULL,
                OperationName       NVARCHAR(200) NOT NULL
            );

            -- Insert operations and capture their new Ids
            INSERT INTO [dbo].[ServiceOperations]
            (
                [ServiceApplicationId],
                [ServiceDefinitionSyncId],
                [OperationName],
                [EndpointOrAction],
                [HttpMethod],
                [Description],
                [IsActive],
                [CreatedAt],
                [CreatedBy]
            )
            OUTPUT inserted.[Id], inserted.[OperationName]
            INTO @InsertedOps (ServiceOperationId, OperationName)
            SELECT
                @ServiceApplicationId,
                @NewDefId,
                src.[OperationName],
                src.[EndpointOrAction],
                src.[HttpMethod],
                src.[Description],
                src.[IsActive],
                GETDATE(),
                @ResolvedUser
            FROM @Operations src;

            -- 3. Insert schemas linked to the new operation Ids
            INSERT INTO [dbo].[ServiceOperationSchemas]
            (
                [ServiceOperationId],
                [InputRootElementName],
                [OutputRootElementName],
                [TargetNamespace],
                [CompressedContent],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [CreatedAt],
                [CreatedBy]
            )
            SELECT
                io.ServiceOperationId,
                src.[InputRootElementName],
                src.[OutputRootElementName],
                src.[TargetNamespace],
                src.[SchemaCompressedContent],
                src.[SchemaUncompressedSizeBytes],
                src.[SchemaCompressionAlgorithmType],
                GETDATE(),
                @ResolvedUser
            FROM @Operations src
            INNER JOIN @InsertedOps io
                ON io.OperationName = src.OperationName;

            -- Result set 1: New definition
            SELECT
                d.[Id]                          AS ServiceDefinitionSyncId,
                d.[ServiceApplicationId],
                d.[DefinitionUrl],
                d.[UncompressedSizeBytes],
                d.[CompressionAlgorithmType],
                d.[RecordVersion],
                d.[CreatedAt],
                d.[CreatedBy],
                CAST(1 AS BIT)                  AS WasCreated,
                'Created'                       AS SaveResult
            FROM [dbo].[ServiceDefinitionSyncs] d
            WHERE d.[Id] = @NewDefId;

            -- Result set 2: Newly inserted operations
            SELECT
                o.[Id]                          AS ServiceOperationId,
                o.[ServiceApplicationId],
                o.[ServiceDefinitionSyncId],
                o.[OperationName],
                o.[EndpointOrAction],
                o.[HttpMethod],
                o.[Description],
                o.[IsActive],
                o.[RecordVersion],
                o.[CreatedAt],
                o.[CreatedBy]
            FROM [dbo].[ServiceOperations] o
            INNER JOIN @InsertedOps io
                ON io.ServiceOperationId = o.[Id]
            ORDER BY o.[OperationName];

            -- Result set 3: Newly inserted schemas
            SELECT
                s.[Id]                          AS ServiceOperationSchemaId,
                s.[ServiceOperationId],
                s.[InputRootElementName],
                s.[OutputRootElementName],
                s.[TargetNamespace],
                s.[UncompressedSizeBytes],
                s.[CompressionAlgorithmType],
                s.[RecordVersion],
                s.[CreatedAt],
                s.[CreatedBy]
            FROM [dbo].[ServiceOperationSchemas] s
            INNER JOIN @InsertedOps io
                ON io.ServiceOperationId = s.[ServiceOperationId]
            ORDER BY io.OperationName;
        END

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR('%s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
