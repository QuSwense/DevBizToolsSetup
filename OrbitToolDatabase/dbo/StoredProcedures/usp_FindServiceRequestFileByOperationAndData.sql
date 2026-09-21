/*
    Stored Procedure: usp_FindServiceRequestFileByOperationAndData

    Finds a service request file by ServiceOperationId and optionally by Name and/or CompressedData.
    Returns the matching row if found, otherwise returns an empty result set with status information.

    Parameters:
        @ServiceOperationId  INT            - The service operation ID to search within (required)
        @Name                NVARCHAR(250)   - The file name to match (optional)
        @CompressedData      VARBINARY(MAX)  - The compressed file data to match (optional)

    Returns:
        Single result set with:
        - ServiceRequestFileId (NULL if not found)
        - PublicId (NULL if not found)
        - ServiceOperationId
        - FileFormat (NULL if not found)
        - Name (NULL if not found)
        - CompressedData (NULL if not found)
        - UncompressedSizeBytes (NULL if not found)
        - CompressionAlgorithmType (NULL if not found)
        - RecordVersion (NULL if not found)
        - IsActive (NULL if not found)
        - CreatedAt (NULL if not found)
        - CreatedBy (NULL if not found)
        - MatchStatus: 0 = NotFound, 1 = MatchedByName, 2 = MatchedByCompressedData, 3 = MatchedByBoth
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_FindServiceRequestFileByOperationAndData]
    @ServiceOperationId INT,
    @Name               NVARCHAR(250) = NULL,
    @CompressedData     VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    /* ---------- Validation ---------- */
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceOperations] WHERE [Id] = @ServiceOperationId)
        RAISERROR('Service operation was not found.', 16, 1);

    IF @Name IS NULL AND @CompressedData IS NULL
        RAISERROR('At least one of Name or CompressedData must be provided.', 16, 1);

    IF @Name IS NOT NULL AND NULLIF(LTRIM(RTRIM(@Name)), '') IS NULL
        RAISERROR('Name cannot be empty or whitespace.', 16, 1);

    /* ---------- Find matching file ---------- */
    DECLARE @MatchStatus TINYINT = 0; -- 0=NotFound, 1=Name, 2=CompressedData, 3=Both

    SELECT TOP 1
        [Id]                        AS ServiceRequestFileId,
        [PublicId],
        [ServiceOperationId],
        [FileFormat],
        [Name],
        [CompressedData],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [RecordVersion],
        [IsActive],
        [CreatedAt],
        [CreatedBy],
        CASE
            WHEN @Name IS NOT NULL AND @CompressedData IS NOT NULL THEN 3
            WHEN @Name IS NOT NULL THEN 1
            WHEN @CompressedData IS NOT NULL THEN 2
            ELSE 0
        END AS MatchStatus
    FROM [dbo].[ServiceRequestFiles]
    WHERE [ServiceOperationId] = @ServiceOperationId
      AND [IsActive] = 1
      AND (
            (@Name IS NOT NULL AND @CompressedData IS NOT NULL AND [Name] = @Name AND [CompressedData] = @CompressedData)
            OR (@Name IS NOT NULL AND @CompressedData IS NULL AND [Name] = @Name)
            OR (@Name IS NULL AND @CompressedData IS NOT NULL AND [CompressedData] = @CompressedData)
          )
    ORDER BY [CreatedAt] DESC;

    /* If no match found, return a row with NULLs and MatchStatus = 0 */
    IF @@ROWCOUNT = 0
    BEGIN
        SELECT
            CAST(NULL AS INT)           AS ServiceRequestFileId,
            CAST(NULL AS UNIQUEIDENTIFIER) AS PublicId,
            @ServiceOperationId         AS ServiceOperationId,
            CAST(NULL AS VARCHAR(10))   AS FileFormat,
            CAST(NULL AS NVARCHAR(250)) AS Name,
            CAST(NULL AS VARBINARY(MAX)) AS CompressedData,
            CAST(NULL AS BIGINT)        AS UncompressedSizeBytes,
            CAST(NULL AS VARCHAR(50))   AS CompressionAlgorithmType,
            CAST(NULL AS VARCHAR(50))   AS RecordVersion,
            CAST(NULL AS BIT)           AS IsActive,
            CAST(NULL AS DATETIME2(3))  AS CreatedAt,
            CAST(NULL AS NVARCHAR(20))  AS CreatedBy,
            0                           AS MatchStatus;
    END
END;
GO