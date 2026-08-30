CREATE TRIGGER [dbo].[trg_ServiceApplications_AutoUpdate]
ON [dbo].[ServiceApplications]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SA]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy],
            [i].[CreatedBy],
            SYSTEM_USER,
            'SYSTEM'
        )
    FROM [dbo].[ServiceApplications] AS [SA]
    INNER JOIN [inserted] AS [i] ON [SA].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SA].[Id] = [d].[Id];
END
GO