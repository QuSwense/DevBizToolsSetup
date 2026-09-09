namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the type of service definition used for a service application.
/// Maps to CK_ServiceApplications_DefinitionType: 'WSDL', 'Swagger', 'OpenAPI'.
/// </summary>
public enum EDefinitionType
{
    /// <summary>WSDL (Web Services Description Language) — used for SOAP services.</summary>
    WSDL = 0,

    /// <summary>Swagger (OpenAPI 2.0) specification.</summary>
    Swagger = 1,

    /// <summary>OpenAPI 3.x specification.</summary>
    OpenAPI = 2
}
