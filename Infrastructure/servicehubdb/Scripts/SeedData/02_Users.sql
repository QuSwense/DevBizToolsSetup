MERGE INTO [dbo].[Users] AS Target
USING (VALUES 
    (
        N'E964484', 
        N'subhadeep.niogi.extern@itergo.com', 
        N'Subhadeep Niogi', 
        1, -- LanguageId (en-US)
        N'TBCD', 
        1, -- IsActive
        0, -- IsDeleted
        N'SYSTEM'
    )
) AS Source (
    [LoginId], 
    [Email], 
    [DisplayName], 
    [LanguageId], 
    [Department], 
    [IsActive], 
    [IsDeleted], 
    [CreatedBy]
)
ON (Target.[LoginId] = Source.[LoginId])
WHEN MATCHED THEN
    UPDATE SET 
        Target.[Email]       = Source.[Email],
        Target.[DisplayName] = Source.[DisplayName],
        Target.[LanguageId]  = Source.[LanguageId],
        Target.[Department]  = Source.[Department],
        Target.[IsActive]    = Source.[IsActive],
        Target.[IsDeleted]   = Source.[IsDeleted],
        Target.[UpdatedBy]   = N'SYSTEM',
        Target.[UpdatedAt]   = GETUTCDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        [LoginId], 
        [Email], 
        [DisplayName], 
        [LanguageId], 
        [Department], 
        [IsActive], 
        [IsDeleted], 
        [CreatedBy], 
        [CreatedAt]
    )
    VALUES (
        Source.[LoginId], 
        Source.[Email], 
        Source.[DisplayName], 
        Source.[LanguageId], 
        Source.[Department], 
        Source.[IsActive], 
        Source.[IsDeleted], 
        Source.[CreatedBy], 
        GETUTCDATE()
    );