namespace OrbitHub.Models.Enums;

/// <summary>
/// Defines the authentication types supported for service application credentials.
/// Maps to CK_ServiceAppAuthentications_Type: 'Basic', 'NTLM', 'APIKey', 'OAuth2', 'Bearer', 'Custom'.
/// </summary>
public enum AuthenticationType
{
    /// <summary>Basic HTTP authentication (username/password).</summary>
    Basic = 0,

    /// <summary>NTLM (Windows NT LAN Manager) authentication.</summary>
    NTLM = 1,

    /// <summary>API key-based authentication.</summary>
    APIKey = 2,

    /// <summary>OAuth 2.0 token-based authentication.</summary>
    OAuth2 = 3,

    /// <summary>Bearer token authentication.</summary>
    Bearer = 4,

    /// <summary>Custom authentication implementation.</summary>
    Custom = 5
}
