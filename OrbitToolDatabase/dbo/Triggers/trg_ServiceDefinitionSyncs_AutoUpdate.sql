CREATE TRIGGER [dbo].[trg_ServiceDefinitionSyncs_AutoUpdate]
ON [dbo].[ServiceDefinitionSyncs]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the row with new version + timestamp
    UPDATE [SDS]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [SyncedAt] = GETDATE()
    FROM [dbo].[ServiceDefinitionSyncs] AS [SDS]
    INNER JOIN [inserted] AS [i] ON [SDS].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SDS].[Id] = [d].[Id];

    -- Audit the change into history table
    INSERT INTO [dbo].[ServiceDefinitionSyncHistorys] (
        [ServiceDefinitionSyncId],
        [ServiceApplicationId],
        [DefinitionUrl],
        [DefinitionContent],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [FileHash],
        [RecordVersion],
        [SyncedAt],
        [SyncedBy],
        [ChangedAt],
        [ChangedBy]
    )
    SELECT
        [d].[Id],                        -- base table Id
        [d].[ServiceApplicationId],
        [d].[DefinitionUrl],
        [d].[DefinitionContent],
        [d].[UncompressedSizeBytes],
        [d].[CompressionAlgorithmType],
        [d].[FileHash],
        [d].[RecordVersion],
        [d].[SyncedAt],
        [d].[SyncedBy],
        GETDATE(),
        COALESCE(
            [i].[SyncedBy],
            SYSTEM_USER,
            'SYSTEM'
        )
    FROM [deleted] AS [d]
    INNER JOIN [inserted] AS [i] ON [d].[Id] = [i].[Id];
END
GO