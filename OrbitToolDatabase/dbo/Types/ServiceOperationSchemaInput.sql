/*
    Table-valued parameter type used by usp_SaveServiceDefinitionWithOperations.

    One row = one operation + its schema payload.
*/
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'ServiceOperationSchemaInput' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[ServiceOperationSchemaInput] AS TABLE
    (
        [OperationName]                     NVARCHAR(200)   NOT NULL,
        [EndpointOrAction]                  NVARCHAR(500)   NULL,
        [HttpMethod]                        VARCHAR(10)     NULL,
        [Description]                       NVARCHAR(MAX)   NULL,
        [IsActive]                          BIT             NOT NULL DEFAULT (1),

        -- Schema fields for this operation
        [InputRootElementName]              NVARCHAR(200)   NULL,
        [OutputRootElementName]             NVARCHAR(200)   NULL,
        [TargetNamespace]                   NVARCHAR(500)   NULL,
        [SchemaCompressedContent]           VARBINARY(MAX)  NOT NULL,
        [SchemaUncompressedSizeBytes]       BIGINT          NULL,
        [SchemaCompressionAlgorithmType]    VARCHAR(50)     NULL
    );
END
GO
