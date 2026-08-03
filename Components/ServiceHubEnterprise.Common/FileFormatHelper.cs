namespace ServiceHubEnterprise.Common;

public static class FileFormatHelper
{
    public static string GetLanguageFromExtension(string? fileName, string? defaultLanguage = null)
    {
        var ext = Path.GetExtension(fileName ?? string.Empty)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "json",
            "xml" or "wsdl" or "soap" => "xml",
            "txt" or "csv" => "plaintext",
            _ => defaultLanguage ?? "xml"
        };
    }

    public static string FormatSize(int byteCount)
    {
        return byteCount switch
        {
            < 1024 => $"{byteCount} B",
            < 1024 * 1024 => $"{byteCount / 1024.0:F1} KB",
            _ => $"{byteCount / (1024.0 * 1024.0):F1} MB"
        };
    }
}
