MERGE INTO [dbo].[AuthTypes] AS Target
USING (VALUES 
    (N'Windows', N'Both',     1, N'SYSTEM'),
    (N'Basic',   N'API',      1, N'SYSTEM'),
    (N'ApiKey',  N'API',      1, N'SYSTEM'),
    (N'SQLAuth', N'Database', 1, N'SYSTEM')
) AS Source ([Name], [AuthCategory], [IsActive], [CreatedBy])
ON (Target.[Name] = Source.[Name])
WHEN MATCHED THEN
    UPDATE SET 
        Target.[AuthCategory] = Source.[AuthCategory],
        Target.[IsActive]     = Source.[IsActive],
        Target.[UpdatedBy]    = N'SYSTEM',
        Target.[UpdatedAt]    = GETUTCDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Name], [AuthCategory], [IsActive], [CreatedBy], [CreatedAt])
    VALUES (Source.[Name], Source.[AuthCategory], Source.[IsActive], Source.[CreatedBy], GETUTCDATE());
