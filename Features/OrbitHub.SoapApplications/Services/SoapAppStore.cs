using System.Text.RegularExpressions;
using LinqToDB;
using LinqToDB.Async;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.SoapManagement;
using OrbitHub.Data.WsdlManagement;
using OrbitHub.SoapApplications.Core.Enums;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store that holds the SOAP application data,
/// shared between Applications.razor and RequestFiles.razor.
/// Loaded from the MSSQL database via SoapDbContext.
/// </summary>
public class SoapAppStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private SoapApp[]? _cached;

    /// <summary>Retrieves all SOAP applications, loading from DB on first access.</summary>
    public SoapApp[] Apps
    {
        get
        {
            if (_cached is not null)
                return _cached;

            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            var apps = db.SoapApps.ToList();
            var apisByApp = db.SoapApis.ToList().ToLookup(a => a.AppId);
            _cached = [.. apps.Select(a => MapToModel(a, apisByApp[a.Id]))];
            return _cached;
        }
    }

    /// <summary>Invalidates the cache so the next access refreshes from DB.</summary>
    public void InvalidateCache()
    {
        _cached = null;
    }

    /// <summary>
    /// Updates the cached apps list. Use after add/edit/delete operations.
    /// Invalidates the cache so the next access refreshes from DB.
    /// </summary>
    public void UpdateApps(SoapApp[] apps)
    {
        _cached = apps;
    }

    private static SoapApp MapToModel(SoapAppEntity entity, IEnumerable<SoapApiEntity> apis)
    {
        return new SoapApp(
            entity.Id,
            entity.Name,
            entity.BaseUrl,
            entity.WsdlPath,
            entity.Description ?? "",
            entity.Status == "enabled" ? AppStatus.Enabled : AppStatus.Disabled,
            entity.CreatedBy,
            DateTime.TryParse(entity.CreatedAt, out var ca) ? ca : DateTime.MinValue,
            entity.UpdatedBy,
            entity.UpdatedAt is not null && DateTime.TryParse(entity.UpdatedAt, out var ua) ? ua : null,
            MapAuthConfig(entity),
            [.. apis.Select(a => new SoapApiEntry { Name = a.Name, Description = a.Description ?? "" })]
        );
    }

    private static SoapAuthConfig MapAuthConfig(SoapAppEntity entity)
    {
        var authType = entity.AuthType switch
        {
            "None" => AuthType.None,
            "Basic" => AuthType.Basic,
            "ApiKey" => AuthType.ApiKey,
            "Bearer" => AuthType.Bearer,
            "Ntlm" => AuthType.Ntlm,
            _ => AuthType.None
        };

        return new SoapAuthConfig
        {
            Type = authType,
            Username = entity.AuthUsername,
            Password = entity.AuthPassword,
            KeyName = entity.AuthKeyName,
            KeyValue = entity.AuthKeyValue,
            Token = entity.AuthToken,
            Domain = entity.AuthDomain
        };
    }
}

/// <summary>
/// Singleton store for WSDL sync records, versions, and templates.
/// Loaded from the MSSQL database via WsdlDbContext on first access.
/// In-memory caching with database persistence.
/// </summary>
public class WsdlSyncStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private List<WsdlSyncRecord>? _records;
    private List<WsdlVersionEntry>? _versions;
    private List<WsdlTemplate>? _templates;
    private List<WsdlSyncHistoryPoint>? _syncHistory;

    /// <summary>All WSDL sync records, lazy-loaded from DB.</summary>
    public List<WsdlSyncRecord> Records
    {
        get
        {
            if (_records is null) LoadFromDb();
            return _records!;
        }
    }

    /// <summary>All WSDL versions, lazy-loaded from DB.</summary>
    public List<WsdlVersionEntry> Versions
    {
        get
        {
            if (_versions is null) LoadFromDb();
            return _versions!;
        }
    }

    /// <summary>All WSDL templates, lazy-loaded from DB.</summary>
    public List<WsdlTemplate> Templates
    {
        get
        {
            if (_templates is null) LoadFromDb();
            return _templates!;
        }
    }

    /// <summary>All WSDL sync history, lazy-loaded from DB.</summary>
    public List<WsdlSyncHistoryPoint> SyncHistory
    {
        get
        {
            if (_syncHistory is null) LoadFromDb();
            return _syncHistory!;
        }
    }

    private void LoadFromDb()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        _records = [.. db.WsdlRecords.Select(r => new WsdlSyncRecord
        {
            Id = r.Id,
            AppId = r.AppId,
            AppName = r.AppName,
            SourceType = r.SourceType,
            SourceUrl = r.SourceUrl ?? "",
            UploadedBy = r.UploadedBy,
            UploadedAt = r.UploadedAt,
            Status = r.Status,
            WsdlContentKey = r.WsdlContentKey ?? "",
        })];

        _versions = [.. db.WsdlVersions.Select(v => new WsdlVersionEntry
        {
            Id = v.Id,
            SyncRecordId = v.SyncRecordId,
            VersionNumber = v.VersionNumber,
            Label = v.Label,
            UploadedBy = v.UploadedBy,
            UploadedAt = v.UploadedAt,
            Status = v.Status,
            Notes = v.Notes ?? ""
        })];

        _templates = [.. db.WsdlTemplates.ToList()
            .Select(t => new WsdlTemplate
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description ?? "",
                Content = t.Content ?? "",
                ExtendsTemplateId = t.ExtendsTemplateId,
                Variables = t.Variables is not null
                    ? System.Text.Json.JsonSerializer.Deserialize<string[]>(t.Variables) ?? []
                    : [],
                CreatedBy = t.CreatedBy,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt
            })];

        _syncHistory = [.. db.WsdlSyncHistory.ToList()
            .Select(h => new WsdlSyncHistoryPoint
            {
                Id = h.Id,
                AppId = h.AppId,
                AppName = h.AppName,
                SyncRecordId = h.SyncRecordId,
                Date = h.Date,
                Status = h.Status,
                Details = h.Details ?? ""
            })];
    }

    /// <summary>Persists all in-memory changes back to the database.</summary>
    public async Task SaveChangesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        await db.WsdlRecords.DeleteAsync();
        await db.WsdlVersions.DeleteAsync();
        await db.WsdlTemplates.DeleteAsync();
        await db.WsdlSyncHistory.DeleteAsync();

        if (_records is not null)
        {
            foreach (var r in _records)
            {
                await db.InsertAsync(new WsdlRecordEntity
                {
                    Id = r.Id,
                    AppId = r.AppId,
                    AppName = r.AppName,
                    SourceType = r.SourceType,
                    SourceUrl = r.SourceUrl,
                    UploadedBy = r.UploadedBy,
                    UploadedAt = r.UploadedAt,
                    Status = r.Status,
                    WsdlContentKey = string.IsNullOrEmpty(r.WsdlContentKey) ? null : r.WsdlContentKey,
                });
            }
        }

        if (_versions is not null)
        {
            foreach (var v in _versions)
            {
                await db.InsertAsync(new WsdlVersionEntity
                {
                    Id = v.Id,
                    SyncRecordId = v.SyncRecordId,
                    VersionNumber = v.VersionNumber,
                    Label = v.Label,
                    UploadedBy = v.UploadedBy,
                    UploadedAt = v.UploadedAt,
                    Status = v.Status,
                    Notes = v.Notes,
                    Content = ""
                });
            }
        }

        if (_templates is not null)
        {
            foreach (var t in _templates)
            {
                await db.InsertAsync(new WsdlTemplateEntity
                {
                    Id = t.Id,
                    Name = t.Name,
                    Description = t.Description,
                    Content = t.Content,
                    ExtendsTemplateId = t.ExtendsTemplateId,
                    Variables = t.Variables is not null
                        ? System.Text.Json.JsonSerializer.Serialize(t.Variables)
                        : null,
                    CreatedBy = t.CreatedBy,
                    CreatedAt = t.CreatedAt,
                    UpdatedAt = t.UpdatedAt
                });
            }
        }

        if (_syncHistory is not null)
        {
            foreach (var h in _syncHistory)
            {
                await db.InsertAsync(new WsdlSyncHistoryEntity
                {
                    Id = h.Id,
                    AppId = h.AppId,
                    AppName = h.AppName,
                    SyncRecordId = h.SyncRecordId,
                    Date = h.Date,
                    Status = h.Status,
                    Details = h.Details
                });
            }
        }
    }

    // ── Convenience methods for backward compatibility ──

    public WsdlSyncRecord[] GetRecordsForApp(string appId) =>
        [.. Records.Where(r => r.AppId == appId).OrderByDescending(r => r.UploadedAt)];

    public WsdlVersionEntry[] GetVersionsForSync(string syncId) =>
        [.. Versions.Where(v => v.SyncRecordId == syncId).OrderByDescending(v => v.VersionNumber)];

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
                        DefaultValue = "",
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

        var tagContentMatches = Regex.Matches(wsdlContent, @">([^<]+)<");
        foreach (Match m in tagContentMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

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

        return [.. vars.OrderBy(v => v)];
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

    public static string ToVariableName(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";
        var cleaned = Regex.Replace(text, @"[^a-zA-Z0-9\s]", " ");
        var parts = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "";
        return string.Join("_", parts.Select(p => p.ToLower())).Trim('_');
    }

    public static string ToLabel(string varName)
    {
        if (string.IsNullOrWhiteSpace(varName)) return "";
        return string.Join(" ", varName.Split('_').Select(w =>
            w.Length > 0 ? char.ToUpper(w[0]) + w[1..] : w));
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

    public WsdlSyncHistoryPoint[] GetSyncHistoryForApp(string appId) =>
        [.. SyncHistory.Where(h => h.AppId == appId).OrderByDescending(h => h.Date)];

    public async Task<string?> GetVersionContentAsync(string versionId)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();
        return await db.WsdlVersions
            .Where(v => v.Id == versionId)
            .Select(v => v.Content)
            .FirstOrDefaultAsync();
    }

    public async Task<string?> GetRecordContentAsync(string? contentKey)
    {
        if (string.IsNullOrEmpty(contentKey)) return null;
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();
        var version = await db.WsdlVersions
            .Join(db.WsdlRecords, v => v.SyncRecordId, r => r.Id, (v, r) => new { v, r })
            .Where(x => x.r.WsdlContentKey == contentKey)
            .OrderByDescending(x => x.v.VersionNumber)
            .Select(x => x.v.Content)
            .FirstOrDefaultAsync();
        return version;
    }

    public async Task AddVersionAsync(string syncRecordId, string label, string content, string uploadedBy)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        var record = await db.WsdlRecords.FirstOrDefaultAsync(r => r.Id == syncRecordId);
        if (record is null) return;

        var maxVersion = await db.WsdlVersions
            .Where(v => v.SyncRecordId == syncRecordId)
            .MaxAsync(v => (int?)v.VersionNumber) ?? 0;

        var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        var newVersion = new WsdlVersionEntity
        {
            Id = $"wv-{Guid.NewGuid():N}"[..12],
            SyncRecordId = syncRecordId,
            VersionNumber = maxVersion + 1,
            Label = label,
            UploadedBy = uploadedBy,
            UploadedAt = now,
            Status = "active",
            Content = content
        };
        await db.InsertAsync(newVersion);

        // Reload in-memory cache
        _versions = null;
        _records = null;
    }

    public async Task RollbackToVersionAsync(string versionId, string uploadedBy)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        var sourceVersion = await db.WsdlVersions.FirstOrDefaultAsync(v => v.Id == versionId);
        if (sourceVersion is null) return;

        await AddVersionAsync(
            sourceVersion.SyncRecordId,
            $"Rollback to {sourceVersion.Label}",
            sourceVersion.Content,
            uploadedBy);
    }
}
