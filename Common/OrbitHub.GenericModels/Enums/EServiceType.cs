namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the type of service application.
/// Maps to CK_ServiceApplications_ServiceType: 'SOAP', 'REST'.
/// </summary>
public enum EServiceType
{
    /// <summary>SOAP (Simple Object Access Protocol) service application.</summary>
    SOAP = 0,

    /// <summary>REST (Representational State Transfer) service application.</summary>
    REST = 1
}
