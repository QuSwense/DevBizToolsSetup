namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the HTTP methods supported for REST service operations.
/// Maps to CK_ServiceOperations_HttpMethod: 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'.
/// </summary>
public enum EHttpMethodType
{
    /// <summary>GET — retrieve a resource.</summary>
    GET = 0,

    /// <summary>POST — create a resource.</summary>
    POST = 1,

    /// <summary>PUT — update/replace a resource.</summary>
    PUT = 2,

    /// <summary>DELETE — remove a resource.</summary>
    DELETE = 3,

    /// <summary>PATCH — partially update a resource.</summary>
    PATCH = 4,

    /// <summary>HEAD — retrieve response headers without the body.</summary>
    HEAD = 5,

    /// <summary>OPTIONS — describe the communication options for a resource.</summary>
    OPTIONS = 6
}
