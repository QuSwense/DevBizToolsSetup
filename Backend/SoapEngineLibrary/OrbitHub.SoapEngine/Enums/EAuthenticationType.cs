namespace ServiceHub.SoapEngine.Core.Enums;

/// <summary>
/// Supported outbound HTTP authentication mechanisms.
/// </summary>
public enum EAuthenticationType
{
    Basic = 1,
    NTLM = 2,
    APIKey = 3,
    OAuth2 = 4,
    None = 5
}
