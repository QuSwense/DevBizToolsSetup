namespace ServiceHubEnterprise.Common;

public static class CsvTextHelper
{
    public static string EncodeField(string? value)
        => $"\"{(value ?? "").Replace("\"", "\"\"")}\"";
}
