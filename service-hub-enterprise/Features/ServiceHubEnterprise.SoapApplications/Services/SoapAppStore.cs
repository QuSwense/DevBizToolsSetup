using System.Text.RegularExpressions;

namespace ServiceHubEnterprise.SoapApplications.Services;

public class SoapApiEntry
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
}

public record SoapApp(string Id, string Name, string BaseUrl, string WsdlPath, string Description, string Status, string CreatedBy, DateTime CreatedAt, string? UpdatedBy, DateTime? UpdatedAt, int ApisCount, string AuthType, string AuthUsername, string AuthPassword, string AuthExtra, SoapApiEntry[] Apis);

/// <summary>
/// A SOAP request file associated with an application (from mock_db/request-files.json).
/// </summary>
public record SoapRequestFile(string FileName, string AppName, string ApiPath, string Verb, string Description, string Status, string CreatedBy, DateTime CreatedAt, string? UpdatedBy, DateTime? UpdatedAt);

/// <summary>
/// Singleton store that holds the SOAP application data,
/// shared between Applications.razor and RequestFiles.razor.
/// </summary>
public class SoapAppStore
{
    public SoapApp[] Apps { get; private set; }

    public SoapAppStore(MockDbLoader loader)
    {
        Apps = loader.LoadJsonAsync<SoapApp[]>("soap-apps.json").GetAwaiter().GetResult();
    }

    public void UpdateApps(SoapApp[] apps)
    {
        Apps = apps;
    }
}

// ── WSDL Sync Models ──

/// <summary>
/// Represents a WSDL sync record linking a SOAP application to its WSDL source.
/// </summary>
public class WsdlSyncRecord
{
    public string Id { get; set; } = "";
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "";
    public string SourceType { get; set; } = "url"; // "url" | "upload"
    public string SourceUrl { get; set; } = "";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "synced"; // "synced" | "failed" | "parsing"
    public string WsdlContent { get; set; } = "";
    public string WsdlContentKey { get; set; } = "";
    public int VersionCount { get; set; } = 1;
}

/// <summary>
/// A specific version snapshot of a WSDL sync record.
/// </summary>
public class WsdlVersionEntry
{
    public string Id { get; set; } = "";
    public string SyncRecordId { get; set; } = "";
    public int VersionNumber { get; set; } = 1;
    public string Label { get; set; } = "v1";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "active"; // "active" | "archived"
    public string Notes { get; set; } = "";
}

/// <summary>
/// A template for generating SOAP request files with {{var_name}} placeholders.
/// A template can extend another template to inherit its content and variables.
/// </summary>
public class WsdlTemplate
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string Content { get; set; } = "";
    public string? ExtendsTemplateId { get; set; }
    public string? ExtendsTemplateName { get; set; }
    public string[] Variables { get; set; } = [];
    public string CreatedBy { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public string? UpdatedBy { get; set; }
    public string? UpdatedAt { get; set; }
    public int UsageCount { get; set; } = 0;
}

/// <summary>
/// Describes a variable extracted from a template for the dynamic form.
/// </summary>
public class TemplateVariableDef
{
    public string Name { get; set; } = "";
    public string Label { get; set; } = "";
    public string DefaultValue { get; set; } = "";
    public string InputType { get; set; } = "text"; // "text" | "textarea" | "select"
    public string[] Options { get; set; } = [];
}

/// <summary>
/// A single WSDL sync status point used for time-series timeline visualization.
/// Dates are stored as "yyyy-MM-dd" strings (relative to today in mock data).
/// </summary>
public class WsdlSyncHistoryPoint
{
    public string Id { get; set; } = "";
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "";
    public string SyncRecordId { get; set; } = "";
    public string Date { get; set; } = ""; // "yyyy-MM-dd"
    public string Status { get; set; } = "synced"; // "synced" | "failed" | "parsing"
    public string Details { get; set; } = "";

    /// <summary>
    /// Attempts to parse the stored date into a DateTime.
    /// </summary>
    public DateTime? TryGetDate()
        => DateTime.TryParseExact(Date, "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var dt) ? dt : null;
}

/// <summary>
/// Singleton store for WSDL sync records, versions, and templates.
/// </summary>
public class WsdlSyncStore
{
    public List<WsdlSyncRecord> Records { get; private set; }
    public List<WsdlVersionEntry> Versions { get; private set; }
    public List<WsdlTemplate> Templates { get; private set; }
    public List<WsdlSyncHistoryPoint> SyncHistory { get; private set; }

    public WsdlSyncStore(MockDbLoader loader)
    {
        Records = loader.LoadJsonAsync<List<WsdlSyncRecord>>("wsdl-records.json").GetAwaiter().GetResult();
        Versions = loader.LoadJsonAsync<List<WsdlVersionEntry>>("wsdl-versions.json").GetAwaiter().GetResult();
        Templates = loader.LoadJsonAsync<List<WsdlTemplate>>("wsdl-templates.json").GetAwaiter().GetResult();
        SyncHistory = loader.LoadJsonAsync<List<WsdlSyncHistoryPoint>>("wsdl-sync-history.json").GetAwaiter().GetResult() ?? [];

        // Preload and resolve WSDL content references
        loader.PreloadAllWsdlContentAsync().GetAwaiter().GetResult();
        foreach (var record in Records)
        {
            if (!string.IsNullOrEmpty(record.WsdlContentKey))
            {
                record.WsdlContent = loader.LoadWsdlContentAsync(record.WsdlContentKey).GetAwaiter().GetResult();
            }
        }
    }

    public WsdlSyncRecord[] GetRecordsForApp(string appId) =>
        Records.Where(r => r.AppId == appId).OrderByDescending(r => r.UploadedAt).ToArray();

    public WsdlVersionEntry[] GetVersionsForSync(string syncId) =>
        Versions.Where(v => v.SyncRecordId == syncId).OrderByDescending(v => v.VersionNumber).ToArray();

    public WsdlTemplate[] GetTemplates() => Templates.OrderBy(t => t.Name).ToArray();

    public WsdlTemplate? GetTemplate(string id) => Templates.FirstOrDefault(t => t.Id == id);

    public WsdlTemplate? ResolveEffectiveTemplate(WsdlTemplate template)
    {
        if (string.IsNullOrEmpty(template.ExtendsTemplateId))
            return template;
        return GetTemplate(template.ExtendsTemplateId);
    }

    /// <summary>
    /// Resolves all variables for a template, including inherited ones from parent templates.
    /// </summary>
    public TemplateVariableDef[] ResolveVariables(WsdlTemplate template)
    {
        var allVars = new List<TemplateVariableDef>();
        var seen = new HashSet<string>();

        // Walk the inheritance chain
        var current = template;
        while (current != null)
        {
            foreach (var varName in current.Variables)
            {
                if (seen.Add(varName))
                {
                    allVars.Add(new TemplateVariableDef
                    {
                        Name = varName,
                        Label = ToLabel(varName),
                        DefaultValue = "",
                        InputType = "text"
                    });
                }
            }
            current = string.IsNullOrEmpty(current.ExtendsTemplateId)
                ? null
                : GetTemplate(current.ExtendsTemplateId);
        }

        return allVars.ToArray();
    }

    /// <summary>
    /// Parses WSDL content to extract variable names between XML tags or in attribute values.
    /// Only looks into values between opening/closing tags and attribute values.
    /// </summary>
    public static string[] ParseWsdlVariables(string wsdlContent)
    {
        if (string.IsNullOrWhiteSpace(wsdlContent))
            return [];

        var vars = new HashSet<string>();

        // Match content between XML tags: <tag>value</tag>
        var tagContentMatches = Regex.Matches(wsdlContent, @">([^<]+)<");
        foreach (Match m in tagContentMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        // Match attribute values: name="value" or name='value'
        var attrValueMatches = Regex.Matches(wsdlContent, @"=\s*""([^""]*)""");
        foreach (Match m in attrValueMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        var attrValueSingleMatches = Regex.Matches(wsdlContent, @"=\s*'([^']*)'");
        foreach (Match m in attrValueSingleMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        return vars.OrderBy(v => v).ToArray();
    }

    private static void AddVariablesFromText(string text, HashSet<string> vars)
    {
        if (string.IsNullOrWhiteSpace(text)) return;

        var candidates = text.Split([' ', '\t', '\n', '\r', ',', ';'], StringSplitOptions.RemoveEmptyEntries);
        foreach (var candidate in candidates)
        {
            var trimmed = candidate.Trim('.', '!', '?', ':');
            if (trimmed.Length > 1 && !int.TryParse(trimmed, out _) &&
                !trimmed.All(c => char.IsPunctuation(c)))
            {
                var suggested = ToVariableName(trimmed);
                if (!string.IsNullOrEmpty(suggested))
                    vars.Add(suggested);
            }
        }
    }

    /// <summary>
    /// Converts arbitrary text to a {{var_name}} compatible variable name.
    /// </summary>
    public static string ToVariableName(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";
        var cleaned = Regex.Replace(text, @"[^a-zA-Z0-9\s]", " ");
        var parts = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "";
        return string.Join("_", parts.Select(p => p.ToLower())).Trim('_');
    }

    /// <summary>
    /// Converts a variable name like "customer_id" to a display label like "Customer ID".
    /// </summary>
    public static string ToLabel(string varName)
    {
        if (string.IsNullOrWhiteSpace(varName)) return "";
        return string.Join(" ", varName.Split('_').Select(w =>
            w.Length > 0 ? char.ToUpper(w[0]) + w[1..] : w));
    }

    /// <summary>
    /// Applies {{var_name}} substitutions to a template content string.
    /// Only supports simple variable paths like {{var_name}}, no complex paths.
    /// </summary>
    public static string ApplyVariables(string content, Dictionary<string, string> values)
    {
        if (string.IsNullOrWhiteSpace(content) || values == null || values.Count == 0)
            return content;

        return Regex.Replace(content, @"\{\{(\w+)\}\}", match =>
        {
            var varName = match.Groups[1].Value;
            return values.TryGetValue(varName, out var val) ? val : match.Value;
        });
    }

    // ── Seed data moved to mock_db/ JSON files ──
    // Loaded dynamically via MockDbLoader.
}
