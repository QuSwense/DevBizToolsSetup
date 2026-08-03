using ServiceHubEnterprise.SoapApplications.Core.Enums;

namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// Holds the authentication details for a SOAP application.
/// Only the fields relevant to <see cref="Type"/> are populated:
/// <list type="bullet">
/// <item><see cref="AuthType.Basic"/>: <see cref="Username"/>, <see cref="Password"/></item>
/// <item><see cref="AuthType.ApiKey"/>: <see cref="KeyName"/>, <see cref="KeyValue"/></item>
/// <item><see cref="AuthType.Bearer"/>: <see cref="Token"/></item>
/// <item><see cref="AuthType.Ntlm"/>: <see cref="Username"/>, <see cref="Password"/>, <see cref="Domain"/></item>
/// <item><see cref="AuthType.None"/>: no fields</item>
/// </list>
/// </summary>
public class SoapAuthConfig
{
    public AuthType Type { get; set; }

    /// <summary>Basic/NTLM username.</summary>
    public string? Username { get; set; }

    /// <summary>Basic/NTLM password.</summary>
    public string? Password { get; set; }

    /// <summary>API key header/param name.</summary>
    public string? KeyName { get; set; }

    /// <summary>API key value.</summary>
    public string? KeyValue { get; set; }

    /// <summary>Bearer token.</summary>
    public string? Token { get; set; }

    /// <summary>NTLM domain.</summary>
    public string? Domain { get; set; }
}
