using System.Text.Json;
using System.Text.Json.Serialization;

namespace OrbitHub.SoapApplications.Core.Enums;

/// <summary>
/// Converts <see cref="EAuthType"/> to/from the string values stored in
/// the database (e.g. "api-key" maps to <see cref="EAuthType.ApiKey"/>,
/// which is not a valid C# enum member name).
/// </summary>
public sealed class AuthTypeJsonConverter : JsonConverter<EAuthType>
{
    private static readonly Dictionary<string, EAuthType> FromString = new(StringComparer.OrdinalIgnoreCase)
    {
        ["none"] = EAuthType.None,
        ["basic"] = EAuthType.Basic,
        ["api-key"] = EAuthType.ApiKey,
        ["bearer"] = EAuthType.Bearer,
        ["ntlm"] = EAuthType.Ntlm
    };

    public override EAuthType Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        var value = reader.GetString();
        if (value is not null && FromString.TryGetValue(value, out var result))
            return result;
        throw new JsonException($"Unknown auth type '{value}'.");
    }

    public override void Write(Utf8JsonWriter writer, EAuthType value, JsonSerializerOptions options)
        => writer.WriteStringValue(value switch
        {
            EAuthType.None => "none",
            EAuthType.Basic => "basic",
            EAuthType.ApiKey => "api-key",
            EAuthType.Bearer => "bearer",
            EAuthType.Ntlm => "ntlm",
            _ => value.ToString()
        });
}
