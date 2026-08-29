using System.Text.Json;
using System.Text.Json.Serialization;

namespace OrbitHub.SoapApplications.Core.Enums;

/// <summary>
/// Converts <see cref="AuthType"/> to/from the string values stored in
/// the database (e.g. "api-key" maps to <see cref="AuthType.ApiKey"/>,
/// which is not a valid C# enum member name).
/// </summary>
public sealed class AuthTypeJsonConverter : JsonConverter<AuthType>
{
    private static readonly Dictionary<string, AuthType> FromString = new(StringComparer.OrdinalIgnoreCase)
    {
        ["none"] = AuthType.None,
        ["basic"] = AuthType.Basic,
        ["api-key"] = AuthType.ApiKey,
        ["bearer"] = AuthType.Bearer,
        ["ntlm"] = AuthType.Ntlm
    };

    public override AuthType Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        var value = reader.GetString();
        if (value is not null && FromString.TryGetValue(value, out var result))
            return result;
        throw new JsonException($"Unknown auth type '{value}'.");
    }

    public override void Write(Utf8JsonWriter writer, AuthType value, JsonSerializerOptions options)
        => writer.WriteStringValue(value switch
        {
            AuthType.None => "none",
            AuthType.Basic => "basic",
            AuthType.ApiKey => "api-key",
            AuthType.Bearer => "bearer",
            AuthType.Ntlm => "ntlm",
            _ => value.ToString()
        });
}
