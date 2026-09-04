namespace ServiceHub.SoapEngine.Core.Enums;

public static class EAuthenticationTypeExtensions
{
    /// <summary>
    /// Converts the enum value to its corresponding database string representation.
    /// </summary>
    public static string ToDbString(this EAuthenticationType authType) => authType switch
    {
        EAuthenticationType.Basic => "Basic",
        EAuthenticationType.NTLM => "NTLM",
        EAuthenticationType.APIKey => "APIKey",
        EAuthenticationType.OAuth2 => "OAuth2",
        _ => throw new ArgumentOutOfRangeException(nameof(authType), authType, null)
    };
}