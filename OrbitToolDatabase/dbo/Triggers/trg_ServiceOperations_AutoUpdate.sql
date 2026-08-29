CREATE TRIGGER [dbo].[trg_ServiceOperations_AutoUpdate]
ON [dbo].[ServiceOperations]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- ServiceOperations doesn't have a history table,
    -- so just update the current record
    UPDATE [SO]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy],
            [i].[CreatedBy],
            SYSTEM_USER,
            'SYSTEM'
        )
    FROM [dbo].[ServiceOperations] AS [SO]
    INNER JOIN [inserted] AS [i] ON [SO].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SO].[Id] = [d].[Id];
END
