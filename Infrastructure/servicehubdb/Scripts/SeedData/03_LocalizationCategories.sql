MERGE INTO [dbo].[LocalizationCategories] AS Target
USING (VALUES 
    (N'Generic',               N'Generic/Shared',         N'Shared resources used across multiple pages', 1),
    (N'AppList',               N'App List',               N'Resources specific to App List page',         1),
    (N'AppDetail',             N'App Detail',             N'Resources specific to App Detail page',       1),
    (N'TestExecution',         N'Test Execution',         N'Resources specific to Test Execution page',   1),
    (N'AuthManagement',        N'Auth Management',        N'Resources specific to Auth Management page',  1),
    (N'TranslationManagement', N'Translation Management', N'Resources specific to Translation Management page', 1)
) AS Source ([Name], [DisplayName], [Description], [IsActive])
ON (Target.[Name] = Source.[Name])
WHEN MATCHED THEN
    UPDATE SET 
        Target.[DisplayName] = Source.[DisplayName],
        Target.[Description] = Source.[Description],
        Target.[IsActive]    = Source.[IsActive]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Name], [DisplayName], [Description], [IsActive])
    VALUES (Source.[Name], Source.[DisplayName], Source.[Description], Source.[IsActive]);