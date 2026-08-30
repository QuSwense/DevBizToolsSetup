CREATE TRIGGER [dbo].[trg_ServiceAppAuthentications_PostUpdate]
ON [dbo].[ServiceAppAuthentications]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SAA]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy],
            [i].[CreatedBy],
            SYSTEM_USER,
            'SYSTEM'
        )
    FROM [dbo].[ServiceAppAuthentications] AS [SAA]
    INNER JOIN [inserted] AS [i] ON [SAA].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SAA].[Id] = [d].[Id];
END
GO