/* Applies MS_Description extended properties to every dbo table column. */
SET NOCOUNT ON;
GO

DECLARE @SchemaName sysname;
DECLARE @TableName sysname;
DECLARE @ColumnName sysname;
DECLARE @Description nvarchar(4000);

DECLARE ColumnDescriptionCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        schema_object.name,
        table_object.name,
        column_object.name,
        CAST(
            CASE
                WHEN column_object.name = N'Id' THEN N'Unique identifier for this ' + table_object.name + N' record.'
                WHEN foreign_key.referenced_table IS NOT NULL THEN N'Identifier of the related ' + foreign_key.referenced_table + N' record.'
                WHEN column_object.name = N'UserId' THEN N'Unique identifier of the user associated with this record.'
                WHEN column_object.name = N'Email' THEN N'Email address of the user.'
                WHEN column_object.name = N'Department' THEN N'Organizational department of the user.'
                WHEN column_object.name = N'FirstName' THEN N'Given name of the user.'
                WHEN column_object.name = N'LastName' THEN N'Family name of the user.'
                WHEN column_object.name = N'Role' THEN N'Application role assigned to the user.'
                WHEN column_object.name = N'PublicId' THEN N'Public identifier used by the UI and external systems (GUID).'
                WHEN column_object.name = N'ServiceType' THEN N'Service protocol category, such as SOAP or REST.'
                WHEN column_object.name = N'Name' THEN N'Human-readable name of this record.'
                WHEN column_object.name = N'Description' THEN N'Optional human-readable description of this record.'
                WHEN column_object.name = N'BaseUrl' THEN N'Base HTTP or HTTPS URL for the service application.'
                WHEN column_object.name = N'DefinitionType' THEN N'Type of service definition, such as WSDL, Swagger, or OpenAPI.'
                WHEN column_object.name = N'DefinitionRelativeUrl' THEN N'Path to the service definition relative to the application base URL.'
                WHEN column_object.name = N'HealthcheckRelativeUrl' THEN N'Path to the health-check endpoint relative to the application base URL.'
                WHEN column_object.name = N'DefinitionUrl' THEN N'Absolute URL from which the service definition was synchronized.'
                WHEN column_object.name = N'AuthenticationType' THEN N'Authentication mechanism used to access a service application.'
                WHEN column_object.name = N'EncryptionAlgorithmType' THEN N'Algorithm used to encrypt stored credentials.'
                WHEN column_object.name = N'EncryptedJson' THEN N'Encrypted JSON document containing authentication credentials.'
                WHEN column_object.name = N'OperationName' THEN N'SOAP operation name or REST endpoint name.'
                WHEN column_object.name = N'EndpointOrAction' THEN N'Service endpoint path or SOAP action for the operation.'
                WHEN column_object.name = N'HttpMethod' THEN N'HTTP method used by the REST operation.'
                WHEN column_object.name = N'InputRootElementName' THEN N'Root element name expected in the operation request payload.'
                WHEN column_object.name = N'OutputRootElementName' THEN N'Root element name expected in the operation response payload.'
                WHEN column_object.name = N'TargetNamespace' THEN N'Target namespace declared by the XML schema.'
                WHEN column_object.name = N'WorkflowName' THEN N'Unique name of the rule workflow.'
                WHEN column_object.name = N'RuleContent' THEN N'JSON definition of the rules in the workflow.'
                WHEN column_object.name = N'RuleTypeId' THEN N'Assembly-qualified .NET type name represented by the rule context.'
                WHEN column_object.name = N'ContextName' THEN N'Unique name of the rule context object.'
                WHEN column_object.name = N'OutputTypeId' THEN N'Identifier of the output type produced by the rule workflow.'
                WHEN column_object.name = N'PermissionKey' THEN N'Unique permission key in the form resource:action, such as soapapplication:read.'
                WHEN column_object.name = N'IsGranted' THEN N'Indicates whether the permission is granted to the user or role.'
                WHEN column_object.name = N'IsSystemRole' THEN N'Indicates whether this is a system-defined role that cannot be deleted or modified.'
                WHEN column_object.name = N'FileFormat' THEN N'Format of the stored file payload, such as XML, JSON, PDF, or BINARY.'
                WHEN column_object.name = N'CompressionAlgorithmType' THEN N'Algorithm used to compress the stored content.'
                WHEN column_object.name = N'CompressedData' OR column_object.name = N'CompressedContent' THEN N'Compressed binary content stored for this record.'
                WHEN column_object.name = N'InputCompressedContent' THEN N'Compressed binary content of the rule input context.'
                WHEN column_object.name = N'OutputCompressedContent' THEN N'Compressed binary content of the rule output result.'
                WHEN column_object.name = N'UncompressedSizeBytes' THEN N'Size of the file content before compression, in bytes.'
                WHEN column_object.name = N'InputUncompressedSizeBytes' THEN N'Size of the rule input content before compression, in bytes.'
                WHEN column_object.name = N'OutputUncompressedSizeBytes' THEN N'Size of the rule output content before compression, in bytes.'
                WHEN column_object.name = N'ContentHash' THEN N'SHA-256 hash of the stored content for integrity verification.'
                WHEN column_object.name = N'FileHash' THEN N'SHA-256 hash of the stored file content.'
                WHEN column_object.name = N'InputContentHash' THEN N'SHA-256 hash of the rule input content.'
                WHEN column_object.name = N'OutputContentHash' THEN N'SHA-256 hash of the rule output content.'
                WHEN column_object.name = N'IsBaseSnapshot' THEN N'Indicates whether this record is a complete base snapshot (1) or a differential delta (0).'
                WHEN column_object.name = N'ParentBaseId' THEN N'Identifier of the base snapshot record in the delta chain.'
                WHEN column_object.name = N'ParentDeltaId' THEN N'Identifier of the immediate predecessor record in the delta chain.'
                WHEN column_object.name = N'DeltaDepth' THEN N'Depth of this record in the delta chain (0 for base snapshots).'
                WHEN column_object.name = N'ElementName' THEN N'Name or key of the indexed element within the file.'
                WHEN column_object.name = N'ElementType' THEN N'Source type of the element, such as XML, JSON, or PDF.'
                WHEN column_object.name = N'KeyPath' THEN N'Path of the element within the file (XPath, JSON path, or element type).'
                WHEN column_object.name = N'ElementValue' THEN N'Scalar value of the indexed element.'
                WHEN column_object.name = N'ValueType' THEN N'Data type of the element value.'
                WHEN column_object.name = N'XmlPath' THEN N'XPath key path of the indexed XML element.'
                WHEN column_object.name = N'JsonPath' THEN N'JSON path key path of the indexed JSON element.'
                WHEN column_object.name = N'PageNumber' THEN N'Page number within the PDF document where the element was found.'
                WHEN column_object.name = N'BoundingRectangle' THEN N'Bounding rectangle coordinates of the PDF element on the page.'
                WHEN column_object.name = N'IndexingXmlFileElementId' THEN N'Identifier of the related XML file element record.'
                WHEN column_object.name = N'IndexingJsonFileElementId' THEN N'Identifier of the related JSON file element record.'
                WHEN column_object.name = N'IndexingPdfFileElementId' THEN N'Identifier of the related PDF file element record.'
                WHEN column_object.name = N'IndexingXmlFileElementSearchId' THEN N'Identifier of the related XML element search record.'
                WHEN column_object.name = N'IndexingJsonFileElementSearchId' THEN N'Identifier of the related JSON element search record.'
                WHEN column_object.name = N'IndexingPdfFileElementSearchId' THEN N'Identifier of the related PDF element search record.'
                WHEN column_object.name = N'BinaryEmbeddingsStoreId' THEN N'Identifier of the related binary embeddings store record.'
                WHEN column_object.name = N'RequestFileId' THEN N'Identifier of the related service request file record.'
                WHEN column_object.name = N'ResponseFileId' THEN N'Identifier of the related service response file record.'
                WHEN column_object.name = N'IndexingStatus' THEN N'Background element-indexing status of the file: Pending, Processing, Completed, or Failed.'
                WHEN column_object.name = N'IndexingFailureReason' THEN N'Error message and stack trace captured when indexing fails.'
                WHEN column_object.name = N'LastIndexedAt' THEN N'Date and time at which background parsing last completed.'
                WHEN column_object.name = N'ActivityType' THEN N'Type of activity performed by the user, such as Login or FeatureUsage.'
                WHEN column_object.name = N'ActionType' THEN N'Granular action type of the activity, such as Click, View, or Edit.'
                WHEN column_object.name = N'FeatureActivitiesJson' THEN N'JSON document containing user feature activity details.'
                WHEN column_object.name = N'Category' THEN N'Category used to group the global setting.'
                WHEN column_object.name = N'SettingKey' THEN N'Unique key that identifies the setting.'
                WHEN column_object.name = N'SettingValue' THEN N'Configured value of the setting.'
                WHEN column_object.name = N'DataType' THEN N'Data type used to interpret the setting value.'
                WHEN column_object.name = N'IsUserOverridable' THEN N'Indicates whether users may override this global setting.'
                WHEN column_object.name = N'ExecutionOrder' THEN N'Order in which the test case runs within its test suite.'
                WHEN column_object.name = N'ExecutionStatus' THEN N'Final status of the execution.'
                WHEN column_object.name = N'ExecutionDetails' THEN N'JSON or text details captured during execution, including errors when applicable.'
                WHEN column_object.name = N'ExecutionTimeMs' THEN N'Rule execution duration in milliseconds.'
                WHEN column_object.name = N'ExecutionCompletedAt' THEN N'Date and time at which execution completed.'
                WHEN column_object.name = N'ExecutedAt' THEN N'Date and time at which execution started.'
                WHEN column_object.name = N'ExecutedBy' THEN N'Identifier of the user who started the execution.'
                WHEN column_object.name = N'HttpStatusCode' THEN N'HTTP status code returned by the service.'
                WHEN column_object.name = N'HttpVersion' THEN N'HTTP protocol version used for the response.'
                WHEN column_object.name = N'HttpRequestDurationMs' THEN N'Total HTTP request duration in milliseconds.'
                WHEN column_object.name = N'HttpRequestHeaders' THEN N'JSON document containing HTTP request headers.'
                WHEN column_object.name = N'HttpResponseHeaders' THEN N'JSON document containing HTTP response headers.'
                WHEN column_object.name = N'HttpContentType' THEN N'Content-Type header returned by the service.'
                WHEN column_object.name = N'HttpContentLength' THEN N'Content length of the service response, in bytes.'
                WHEN column_object.name = N'ErrorMessage' THEN N'Error message captured when execution fails.'
                WHEN column_object.name = N'IsSuccess' THEN N'Indicates whether the execution completed successfully.'
                WHEN column_object.name = N'RecordVersion' THEN N'Application-managed version value used for record change tracking.'
                WHEN column_object.name = N'IsActive' THEN N'Indicates whether this record is active and available for use.'
                WHEN column_object.name = N'IsVisibleInNav' THEN N'Indicates whether this page is shown in the navigation menu.'
                WHEN column_object.name = N'RequiredPermissionKey' THEN N'Permission key required to view this page or perform this action.'
                WHEN column_object.name = N'FeatureFlag' THEN N'Name of the feature flag that controls whether this page is visible.'
                WHEN column_object.name = N'ActionName' THEN N'Name of the UI action, such as Create, Edit, or Delete.'
                WHEN column_object.name = N'DisplayName' THEN N'Human-readable label shown for this UI action.'
                WHEN column_object.name = N'ActionType' THEN N'Type of UI element for the action, such as Button, MenuItem, Tab, or Link.'
                WHEN column_object.name = N'UiElementId' THEN N'CSS or UI identifier of the element that triggers this action.'
                WHEN column_object.name = N'AccessType' THEN N'Access level granted by the mapping, such as View, Edit, or Full.'
                WHEN column_object.name = N'CreatedAt' OR column_object.name = N'CreatedDate' THEN N'Date and time at which this record was created.'
                WHEN column_object.name = N'CreatedBy' THEN N'Identifier of the user who created this record.'
                WHEN column_object.name = N'LastUpdatedAt' THEN N'Date and time at which this record was last updated.'
                WHEN column_object.name = N'LastUpdatedBy' THEN N'Identifier of the user who last updated this record.'
                WHEN column_object.name = N'LastUpdatedDate' THEN N'Date and time at which this record was last updated.'
                WHEN column_object.name = N'UpdatedAt' THEN N'Date and time at which this record was last updated.'
                WHEN column_object.name = N'Timestamp' THEN N'Date and time at which the user activity was recorded.'
                ELSE N'Value of the ' + column_object.name + N' field for this ' + table_object.name + N' record.'
            END AS nvarchar(4000))
    FROM sys.tables AS table_object
    INNER JOIN sys.schemas AS schema_object
        ON schema_object.schema_id = table_object.schema_id
    INNER JOIN sys.columns AS column_object
        ON column_object.object_id = table_object.object_id
    OUTER APPLY (
        SELECT TOP (1) referenced_table.name AS referenced_table
        FROM sys.foreign_key_columns AS foreign_key_column
        INNER JOIN sys.tables AS referenced_table
            ON referenced_table.object_id = foreign_key_column.referenced_object_id
        WHERE foreign_key_column.parent_object_id = table_object.object_id
          AND foreign_key_column.parent_column_id = column_object.column_id
    ) AS foreign_key
    WHERE schema_object.name = N'dbo'
    ORDER BY table_object.name, column_object.column_id;

OPEN ColumnDescriptionCursor;
FETCH NEXT FROM ColumnDescriptionCursor INTO @SchemaName, @TableName, @ColumnName, @Description;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.extended_properties AS property
        INNER JOIN sys.tables AS table_object ON table_object.object_id = property.major_id
        INNER JOIN sys.schemas AS schema_object ON schema_object.schema_id = table_object.schema_id
        INNER JOIN sys.columns AS column_object
            ON column_object.object_id = table_object.object_id
           AND column_object.column_id = property.minor_id
        WHERE property.name = N'MS_Description'
          AND schema_object.name = @SchemaName
          AND table_object.name = @TableName
          AND column_object.name = @ColumnName
    )
        EXEC sys.sp_updateextendedproperty
            @name = N'MS_Description', @value = @Description,
            @level0type = N'SCHEMA', @level0name = @SchemaName,
            @level1type = N'TABLE', @level1name = @TableName,
            @level2type = N'COLUMN', @level2name = @ColumnName;
    ELSE
        EXEC sys.sp_addextendedproperty
            @name = N'MS_Description', @value = @Description,
            @level0type = N'SCHEMA', @level0name = @SchemaName,
            @level1type = N'TABLE', @level1name = @TableName,
            @level2type = N'COLUMN', @level2name = @ColumnName;

    FETCH NEXT FROM ColumnDescriptionCursor INTO @SchemaName, @TableName, @ColumnName, @Description;
END;

CLOSE ColumnDescriptionCursor;
DEALLOCATE ColumnDescriptionCursor;
GO