using System.Text.RegularExpressions;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Views;
using OrbitHub.SoapApplications.Core.Enums;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store that holds the SOAP application data,
/// shared between Applications.razor and RequestFiles.razor.
/// The legacy database-backed SOAP tables were removed from the generated model,
/// so this implementation loads the current view repositories and safely falls back to an empty list.
/// </summary>
public class SoapAppStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private SoapApp[]? _cached;

    /// <summary>Retrieves all SOAP applications, loading from current view data on first access.</summary>
    public SoapApp[] Apps
    {
        get
        {
            if (_cached is not null)
                return _cached;

            _cached = LoadAppsFromData();
            return _cached;
        }
    }

    public void InvalidateCache() => _cached = null;

    public void UpdateApps(SoapApp[] apps) => _cached = apps;

    private SoapApp[] LoadAppsFromData()
    {
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var appsView = scope.ServiceProvider.GetRequiredService<LatestServiceApplicationWithAuthViewRepository>();
            var opsView = scope.ServiceProvider.GetRequiredService<ServiceOperationsSummaryViewRepository>();

            var applications = ReadResult(appsView.GetAllAsync().GetAwaiter().GetResult());
            var operations = ReadResult(opsView.GetAllAsync().GetAwaiter().GetResult());
            var operationsByApp = operations.ToLookup(o => o.ServicePublicId, StringComparer.OrdinalIgnoreCase);

            return [..
                applications
                    .Where(a => a.ServiceType.Equals("SOAP", StringComparison.OrdinalIgnoreCase))
                    .Select(a => new SoapApp(
                        Id: a.ServiceApplicationId,
                        Name: a.ServiceApplicationName,
                        BaseUrl: a.BaseUrl ?? string.Empty,
                        WsdlPath: a.DefinitionRelativeUrl ?? string.Empty,
                        Description: a.Description ?? string.Empty,
                        Status: a.IsActive == true ? AppStatus.Enabled : AppStatus.Disabled,
                        CreatedBy: a.ServiceAppCreatedBy ?? string.Empty,
                        CreatedAt: a.ServiceAppCreatedAt ?? DateTime.MinValue,
                        UpdatedBy: a.ServiceAppLastUpdatedBy,
                        UpdatedAt: a.ServiceAppLastUpdatedAt,
                        Auth: new SoapAuthConfig { Type = ParseAuthType(a.AuthenticationType) },
                        Apis: [.. BuildApIs(a, operationsByApp)]
                    ))];
        }
        catch
        {
            return [];
        }
    }

    private static IReadOnlyList<SoapApiEntry> BuildApIs(
        LatestServiceApplicationWithAuthView app,
        ILookup<string, ServiceOperationsSummaryView> operationsByApp)
    {
        var names = operationsByApp[app.ServiceApplicationId]
            .SelectMany(o => (o.AllOperationNames ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        return names.Length == 0
            ? [new SoapApiEntry { Name = app.ServiceApplicationName, Description = app.Description ?? string.Empty }]
            : [.. names.Select(name => new SoapApiEntry { Name = name, Description = name })];
    }

    private static AuthType ParseAuthType(string? authenticationType) => authenticationType?.Trim() switch
    {
        "Basic" => AuthType.Basic,
        "Bearer" => AuthType.Bearer,
        "ApiKey" => AuthType.ApiKey,
        "Ntlm" => AuthType.Ntlm,
        _ => AuthType.None
    };

    private static List<T> ReadResult<T>(RepositoryResult<List<T>> result)
        => result.Success && result.Data is not null ? result.Data : [];
}

/// <summary>
/// Singleton store for WSDL sync records, versions, and templates.
/// The generated data model no longer includes the legacy WSDL tables, so the feature keeps
/// the same public API while operating from a safe in-memory registry.
/// </summary>
public class WsdlSyncStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private List<WsdlSyncRecord>? _records;
    private List<WsdlVersionEntry>? _versions;
    private List<WsdlTemplate>? _templates;
    private List<WsdlSyncHistoryPoint>? _syncHistory;

    public List<WsdlSyncRecord> Records => _records ??= [];
    public List<WsdlVersionEntry> Versions => _versions ??= [];
    public List<WsdlTemplate> Templates => _templates ??= [];
    public List<WsdlSyncHistoryPoint> SyncHistory => _syncHistory ??= [];

    public Task SaveChangesAsync() => Task.CompletedTask;

    public WsdlSyncRecord[] GetRecordsForApp(string appId) => [.. Records.Where(r => r.AppId == appId).OrderByDescending(r => r.UploadedAt)];

    public WsdlVersionEntry[] GetVersionsForSync(string syncId) => [.. Versions.Where(v => v.SyncRecordId == syncId).OrderByDescending(v => v.VersionNumber)];

    public WsdlTemplate[] GetTemplates() => [.. Templates.OrderBy(t => t.Name)];

    public WsdlTemplate? GetTemplate(string id) => Templates.FirstOrDefault(t => t.Id == id);

    public WsdlTemplate? ResolveEffectiveTemplate(WsdlTemplate template)
    {
        if (string.IsNullOrEmpty(template.ExtendsTemplateId))
            return template;
        return GetTemplate(template.ExtendsTemplateId);
    }

    public TemplateVariableDef[] ResolveVariables(WsdlTemplate template)
    {
        var allVars = new List<TemplateVariableDef>();
        var seen = new HashSet<string>();

        var current = template;
        while (current is not null)
        {
            foreach (var varName in current.Variables)
            {
                if (seen.Add(varName))
                {
                    allVars.Add(new TemplateVariableDef
                    {
                        Name = varName,
                        Label = ToLabel(varName),
                        DefaultValue = string.Empty,
                        InputType = "text"
                    });
                }
            }

            current = string.IsNullOrEmpty(current.ExtendsTemplateId)
                ? null
                : GetTemplate(current.ExtendsTemplateId);
        }

        return [.. allVars];
    }

    public static string[] ParseWsdlVariables(string wsdlContent)
    {
        if (string.IsNullOrWhiteSpace(wsdlContent)) return [];
        var vars = new HashSet<string>();

        foreach (Match match in Regex.Matches(wsdlContent, @">([^<]+)<"))
        {
            var content = match.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        foreach (Match match in Regex.Matches(wsdlContent, @"=\s*""([^""]*)"""))
        {
            var content = match.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        foreach (Match match in Regex.Matches(wsdlContent, @"=\s*'([^']*)'"))
        {
            var content = match.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        return [.. vars.OrderBy(v => v)];
    }

    private static void AddVariablesFromText(string text, HashSet<string> vars)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        var candidates = text.Split([' ', '\t', '\n', '\r', ',', ';'], StringSplitOptions.RemoveEmptyEntries);
        foreach (var candidate in candidates)
        {
            var trimmed = candidate.Trim('.', '!', '?', ':');
            if (trimmed.Length > 1 && !int.TryParse(trimmed, out _) && !trimmed.All(char.IsPunctuation))
            {
                var suggested = ToVariableName(trimmed);
                if (!string.IsNullOrEmpty(suggested))
                    vars.Add(suggested);
            }
        }
    }

    public static string ToVariableName(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;
        var cleaned = Regex.Replace(text, @"[^a-zA-Z0-9\s]", " ");
        var parts = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length == 0 ? string.Empty : string.Join("_", parts.Select(p => p.ToLowerInvariant())).Trim('_');
    }

    public static string ToLabel(string varName)
    {
        if (string.IsNullOrWhiteSpace(varName)) return string.Empty;
        return string.Join(" ", varName.Split('_').Select(w => w.Length > 0 ? char.ToUpperInvariant(w[0]) + w[1..] : w));
    }

    public static string ApplyVariables(string content, Dictionary<string, string> values)
    {
        if (string.IsNullOrWhiteSpace(content) || values is null || values.Count == 0)
            return content;

        return Regex.Replace(content, @"\{\{(\w+)\}\}", match =>
        {
            var varName = match.Groups[1].Value;
            return values.TryGetValue(varName, out var val) ? val : match.Value;
        });
    }

    public WsdlSyncHistoryPoint[] GetSyncHistoryForApp(string appId) => [.. SyncHistory.Where(h => h.AppId == appId).OrderByDescending(h => h.Date)];

    public Task<string?> GetVersionContentAsync(string versionId)
    {
        var version = Versions.FirstOrDefault(v => v.Id == versionId);
        if (version is null)
            return Task.FromResult<string?>(null);

        var template = _templates?.FirstOrDefault(t => t.Id == versionId);
        return Task.FromResult<string?>(template?.Content ?? string.Empty);
    }

    public Task<string?> GetRecordContentAsync(string? contentKey)
    {
        if (string.IsNullOrEmpty(contentKey)) return Task.FromResult<string?>(null);
        var record = Records.FirstOrDefault(r => r.WsdlContentKey == contentKey);
        return Task.FromResult(record is null ? null : record.WsdlContent);
    }

    public Task AddVersionAsync(string syncRecordId, string label, string content, string uploadedBy)
    {
        var record = Records.FirstOrDefault(r => r.Id == syncRecordId);
        if (record is null)
            return Task.CompletedTask;

        var version = new WsdlVersionEntry
        {
            Id = $"wv-{Guid.NewGuid():N}"[..12],
            SyncRecordId = syncRecordId,
            VersionNumber = Versions.Count(v => v.SyncRecordId == syncRecordId) + 1,
            Label = label,
            UploadedBy = uploadedBy,
            UploadedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
            Status = "active",
            Notes = string.Empty
        };

        Versions.Add(version);
        if (_templates is not null)
        {
            var template = _templates.FirstOrDefault(t => t.Id == record.Id) ?? new WsdlTemplate { Id = record.Id, Name = record.AppName, Content = content };
            template.Content = content;
            if (!_templates.Any(t => t.Id == template.Id))
                _templates.Add(template);
        }

        record.WsdlContent = content;
        return Task.CompletedTask;
    }

    public Task RollbackToVersionAsync(string versionId, string uploadedBy)
    {
        var version = Versions.FirstOrDefault(v => v.Id == versionId);
        if (version is null)
            return Task.CompletedTask;

        return AddVersionAsync(version.SyncRecordId, $"Rollback to {version.Label}", GetRecordContentAsync(version.SyncRecordId).GetAwaiter().GetResult() ?? string.Empty, uploadedBy);
    }
}
