CREATE TRIGGER [dbo].[trg_ServiceRequestFiles_Audit]
ON [dbo].[ServiceRequestFiles]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the main table with LastUpdatedAt
    UPDATE [SRF]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy],
            [i].[CreatedBy],
            SYSTEM_USER,
            'SYSTEM'
        )
    FROM [dbo].[ServiceRequestFiles] AS [SRF]
    INNER JOIN [inserted] AS [i] ON [SRF].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SRF].[Id] = [d].[Id];

    -- Insert audit history (the OLD values from deleted)
    INSERT INTO [dbo].[ServiceRequestFileHistorys] (
        [ServiceRequestFileId],
        [FileFormat],
        [FileName],
        [FileData],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [FileHash],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy]
    )
    SELECT
        [d].[Id], -- Main table Id becomes ServiceRequestFileId in history
        [d].[FileFormat],
        [d].[FileName],
        [d].[FileData],
        [d].[UncompressedSizeBytes],
        [d].[CompressionAlgorithmType],
        [d].[FileHash],
        [d].[CreatedAt],
        [d].[CreatedBy],
        GETDATE(), -- LastUpdatedAt in history = when change happened
        [i].[LastUpdatedBy] -- Who made the change
    FROM [deleted] AS [d]
    INNER JOIN [inserted] AS [i] ON [d].[Id] = [i].[Id];
END
GO