using System.Text.RegularExpressions;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services;

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
