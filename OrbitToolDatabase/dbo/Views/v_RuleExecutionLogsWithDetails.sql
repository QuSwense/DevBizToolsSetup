/*
    View: v_RuleExecutionLogsWithDetails
    Description: Comprehensive view of rule execution logs.
*/
CREATE VIEW [dbo].[v_RuleExecutionLogsWithDetails]
AS
SELECT 
    rel.[Id] AS LogId,
    rel.[RuleSetId],
    rel.[InputCompressedContent],
    rel.[InputUncompressedSizeBytes],
    rel.[InputContentHash],
    rel.[OutputCompressedContent],
    rel.[OutputUncompressedSizeBytes],
    rel.[OutputContentHash],
    rel.[CompressionAlgorithmType],
    rel.[IsSuccess],
    rel.[ErrorMessage],
    rel.[ExecutionTimeMs],
    rel.[ExecutedAt],
    rel.[ExecutedBy],
    
    -- Rule Set details
    rs.[WorkflowName],
    rs.[OutputTypeId],
    rs.[RecordVersion] AS RuleSetVersion,
    rs.[Description] AS RuleSetDescription,
    
    -- User details
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS ExecutedByFullName,
    u.[Email] AS ExecutedByEmail,
    
    -- Human readable sizes
    CASE 
        WHEN rel.[InputUncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(rel.[InputUncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN rel.[InputUncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(rel.[InputUncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), rel.[InputUncompressedSizeBytes]) + ' bytes'
    END AS InputSizeHuman,
    
    CASE 
        WHEN rel.[OutputUncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(rel.[OutputUncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN rel.[OutputUncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(rel.[OutputUncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), rel.[OutputUncompressedSizeBytes]) + ' bytes'
    END AS OutputSizeHuman,
    
    -- Hash short
    LEFT(rel.[InputContentHash], 16) + '...' AS InputHashShort,
    LEFT(rel.[OutputContentHash], 16) + '...' AS OutputHashShort,
    
    -- Status
    CASE 
        WHEN rel.[IsSuccess] = 1 THEN 'Success'
        ELSE 'Failed'
    END AS ExecutionStatus,
    
    -- Execution time in seconds
    CAST(rel.[ExecutionTimeMs] / 1000.0 AS DECIMAL(10,2)) AS ExecutionTimeSeconds,
    
    -- Age
    DATEDIFF(DAY, rel.[ExecutedAt], GETDATE()) AS AgeDays,
    DATEDIFF(HOUR, rel.[ExecutedAt], GETDATE()) AS AgeHours

FROM [dbo].[RuleExecutionLogs] rel
INNER JOIN [dbo].[RuleSets] rs ON rel.[RuleSetId] = rs.[Id]
INNER JOIN [dbo].[Users] u ON rel.[ExecutedBy] = u.[UserId];
GO