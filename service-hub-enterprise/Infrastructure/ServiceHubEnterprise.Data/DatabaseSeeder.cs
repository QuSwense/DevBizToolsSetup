using System.Text.Json;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// Seeds the ServiceHub SQLite database from mock_db JSON files and loose XML/WSDL files.
/// Idempotent — only seeds if the database is empty.
/// </summary>
public class DatabaseSeeder
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly string _mockDbRoot;
    private readonly string _connectionString;
    private readonly SoapDbContext _soap;
    private readonly RestDbContext _rest;
    private readonly DashboardDbContext _dashboard;
    private readonly WsdlDbContext _wsdl;

    public DatabaseSeeder(
        IConfiguration configuration,
        SoapDbContext soap,
        RestDbContext rest,
        DashboardDbContext dashboard,
        WsdlDbContext wsdl)
    {
        // Resolve mock_db root relative to the web app's current directory
        _mockDbRoot = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "mock_db");
        _connectionString = ServiceHubDataConfig.GetConnectionString(configuration);
        _soap = soap;
        _rest = rest;
        _dashboard = dashboard;
        _wsdl = wsdl;
    }

    /// <summary>
    /// Seeds all tables if the database is empty. Idempotent.
    /// </summary>
    public async Task SeedIfEmptyAsync()
    {
        // Execute schema.sql to create ALL tables at once (avoids EnsureCreated
        // skipping tables when multiple DbContexts share the same database file)
        await EnsureSchemaCreatedAsync();

        // Check if already seeded (use SoapApps as canary)
        if (await _soap.SoapApps.AnyAsync())
            return;

        await SeedSoapAppsAsync();
        await SeedSoapRequestFilesAsync();
        await SeedRestAppsAsync();
        await SeedRestRequestFilesAsync();
        await SeedWsdlDataAsync();
        await SeedDashboardDataAsync();
    }

    /// <summary>
    /// Executes schema.sql against the SQLite database to create all tables.
    /// Uses raw ADO.NET to run the full multi-statement script in one command.
    /// </summary>
    private async Task EnsureSchemaCreatedAsync()
    {
        // Resolve schema.sql relative to the web app's working directory
        // CWD = WebApp/ServiceHubEnterprise.Web/
        // schema.sql = ../../Infrastructure/ServiceHubEnterprise.Data/Scripts/schema.sql
        var schemaPath = Path.Combine(
            Directory.GetCurrentDirectory(),
            "..", "..",
            "Infrastructure", "ServiceHubEnterprise.Data", "Scripts", "schema.sql");

        if (!File.Exists(schemaPath))
            throw new FileNotFoundException(
                "Cannot find schema.sql. Expected at: " + schemaPath, "schema.sql");

        var sql = await File.ReadAllTextAsync(schemaPath);

        await using var connection = new SqliteConnection(_connectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();
    }

    // ──────────────────────────────────────────────
    //  SOAP
    // ──────────────────────────────────────────────

    private async Task SeedSoapAppsAsync()
    {
        var path = Path.Combine(_mockDbRoot, "Soap", "soap-apps.json");
        if (!File.Exists(path)) return;

        using var doc = JsonDocument.Parse(File.ReadAllText(path));
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            var authType = MapAuthType(el.GetProperty("auth").GetProperty("type").GetString() ?? "none");
            var auth = el.GetProperty("auth");

            var entity = new SoapAppEntity
            {
                Id = el.GetProperty("id").GetString() ?? "",
                Name = el.GetProperty("name").GetString() ?? "",
                BaseUrl = el.GetProperty("baseUrl").GetString() ?? "",
                WsdlPath = el.GetProperty("wsdlPath").GetString() ?? "",
                Description = el.GetProperty("description").GetString() ?? "",
                Status = el.GetProperty("status").GetString() ?? "enabled",
                CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                UpdatedBy = GetNullableString(el, "updatedBy"),
                CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                UpdatedAt = GetNullableString(el, "updatedAt"),
                ApisCount = el.GetProperty("apisCount").GetInt32(),
                AuthType = authType,
                AuthUsername = GetNullableString(auth, "username"),
                AuthPassword = GetNullableString(auth, "password"),
                AuthKeyName = GetNullableString(auth, "keyName"),
                AuthKeyValue = GetNullableString(auth, "keyValue"),
                AuthToken = GetNullableString(auth, "token"),
                AuthDomain = GetNullableString(auth, "domain"),
            };

            // Seed APIs
            if (el.TryGetProperty("apis", out var apisProp))
            {
                var apiIndex = 0;
                foreach (var apiEl in apisProp.EnumerateArray())
                {
                    apiIndex++;
                    entity.Apis.Add(new SoapApiEntity
                    {
                        Id = $"{entity.Id}-api-{apiIndex}",
                        AppId = entity.Id,
                        Name = apiEl.GetProperty("name").GetString() ?? "",
                        Description = apiEl.GetProperty("description").GetString() ?? ""
                    });
                }
            }

            _soap.SoapApps.Add(entity);
        }

        await _soap.SaveChangesAsync();
    }

    private async Task SeedSoapRequestFilesAsync()
    {
        var jsonPath = Path.Combine(_mockDbRoot, "Soap", "Request", "request-files.json");
        if (!File.Exists(jsonPath)) return;

        var requestDir = Path.Combine(_mockDbRoot, "Soap", "Request");

        using var doc = JsonDocument.Parse(File.ReadAllText(jsonPath));
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            var fileName = el.GetProperty("fileName").GetString() ?? "";

            // Read content from loose .xml file if it exists
            var xmlPath = Path.Combine(requestDir, fileName);
            string? content = null;
            if (File.Exists(xmlPath))
            {
                content = await File.ReadAllTextAsync(xmlPath);
            }

            var entity = new SoapRequestFileEntity
            {
                Id = $"srf-{Guid.NewGuid():N}"[..12],
                FileName = fileName,
                AppName = el.GetProperty("appName").GetString() ?? "",
                ApiPath = el.GetProperty("apiPath").GetString() ?? "",
                Verb = el.GetProperty("verb").GetString() ?? "POST",
                Description = el.GetProperty("description").GetString() ?? "",
                Status = el.GetProperty("status").GetString() ?? "active",
                CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                UpdatedBy = GetNullableString(el, "updatedBy"),
                UpdatedAt = GetNullableString(el, "updatedAt"),
                Content = content
            };

            _soap.SoapRequestFiles.Add(entity);
        }

        await _soap.SaveChangesAsync();
    }

    // ──────────────────────────────────────────────
    //  REST
    // ──────────────────────────────────────────────

    private async Task SeedRestAppsAsync()
    {
        var path = Path.Combine(_mockDbRoot, "Rest", "rest-apps.json");
        if (!File.Exists(path)) return;

        using var doc = JsonDocument.Parse(File.ReadAllText(path));
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            _rest.RestApps.Add(new RestAppEntity
            {
                Id = el.GetProperty("id").GetString() ?? "",
                Name = el.GetProperty("name").GetString() ?? "",
                BaseUrl = el.GetProperty("baseUrl").GetString() ?? "",
                Description = el.GetProperty("description").GetString() ?? "",
                Status = el.GetProperty("status").GetString() ?? "enabled",
                CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                UpdatedBy = GetNullableString(el, "updatedBy"),
                UpdatedAt = GetNullableString(el, "updatedAt"),
                ApisCount = el.GetProperty("apisCount").GetInt32()
            });
        }

        await _rest.SaveChangesAsync();
    }

    private async Task SeedRestRequestFilesAsync()
    {
        var path = Path.Combine(_mockDbRoot, "Rest", "rest-request-files.json");
        if (!File.Exists(path)) return;

        using var doc = JsonDocument.Parse(File.ReadAllText(path));
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            _rest.RestRequestFiles.Add(new RestRequestFileEntity
            {
                Id = $"rrf-{Guid.NewGuid():N}"[..12],
                FileName = el.GetProperty("fileName").GetString() ?? "",
                AppName = el.GetProperty("appName").GetString() ?? "",
                ApiPath = el.GetProperty("apiPath").GetString() ?? "",
                Verb = el.GetProperty("verb").GetString() ?? "GET",
                Description = el.GetProperty("description").GetString() ?? "",
                Status = el.GetProperty("status").GetString() ?? "active",
                CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                UpdatedBy = GetNullableString(el, "updatedBy"),
                UpdatedAt = GetNullableString(el, "updatedAt")
            });
        }

        await _rest.SaveChangesAsync();
    }

    // ──────────────────────────────────────────────
    //  WSDL
    // ──────────────────────────────────────────────

    private async Task SeedWsdlDataAsync()
    {
        // Seed WSDL records
        var recordsPath = Path.Combine(_mockDbRoot, "Wsdl", "wsdl-records.json");
        if (File.Exists(recordsPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(recordsPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _wsdl.WsdlRecords.Add(new WsdlRecordEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    AppId = el.GetProperty("appId").GetString() ?? "",
                    AppName = el.GetProperty("appName").GetString() ?? "",
                    SourceType = el.GetProperty("sourceType").GetString() ?? "url",
                    SourceUrl = el.GetProperty("sourceUrl").GetString() ?? "",
                    UploadedBy = el.GetProperty("uploadedBy").GetString() ?? "",
                    UploadedAt = el.GetProperty("uploadedAt").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "synced",
                    WsdlContentKey = GetNullableString(el, "wsdlContentKey"),
                    VersionCount = el.GetProperty("versionCount").GetInt32()
                });
            }
        }

        // Seed WSDL versions
        var versionsPath = Path.Combine(_mockDbRoot, "Wsdl", "wsdl-versions.json");
        if (File.Exists(versionsPath))
        {
            // Read content map for .wsdl files
            var contentMapPath = Path.Combine(_mockDbRoot, "Wsdl", "wsdl-content-map.json");
            Dictionary<string, string>? contentMap = null;
            if (File.Exists(contentMapPath))
            {
                contentMap = JsonSerializer.Deserialize<Dictionary<string, string>>(
                    File.ReadAllText(contentMapPath));
            }

            using var doc = JsonDocument.Parse(File.ReadAllText(versionsPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                // Resolve WSDL content from .wsdl files
                string? content = null;
                if (contentMap != null)
                {
                    // Find the parent record's wsdlContentKey to resolve content
                    var syncRecordId = el.GetProperty("syncRecordId").GetString() ?? "";
                    var record = _wsdl.WsdlRecords.Local.FirstOrDefault(r => r.Id == syncRecordId);
                    if (record?.WsdlContentKey != null && contentMap.TryGetValue(record.WsdlContentKey, out var relPath))
                    {
                        var wsdlFilePath = Path.Combine(_mockDbRoot, relPath);
                        if (File.Exists(wsdlFilePath))
                        {
                            content = await File.ReadAllTextAsync(wsdlFilePath);
                        }
                    }
                }

                _wsdl.WsdlVersions.Add(new WsdlVersionEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    SyncRecordId = el.GetProperty("syncRecordId").GetString() ?? "",
                    VersionNumber = el.GetProperty("versionNumber").GetInt32(),
                    Label = el.GetProperty("label").GetString() ?? "",
                    UploadedBy = el.GetProperty("uploadedBy").GetString() ?? "",
                    UploadedAt = el.GetProperty("uploadedAt").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "active",
                    Notes = GetNullableString(el, "notes"),
                    Content = content ?? ""
                });
            }
        }

        // Seed WSDL sync history
        var historyPath = Path.Combine(_mockDbRoot, "Wsdl", "wsdl-sync-history.json");
        if (File.Exists(historyPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(historyPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _wsdl.WsdlSyncHistory.Add(new WsdlSyncHistoryEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    AppId = el.GetProperty("appId").GetString() ?? "",
                    AppName = el.GetProperty("appName").GetString() ?? "",
                    SyncRecordId = el.GetProperty("syncRecordId").GetString() ?? "",
                    Date = el.GetProperty("date").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "",
                    Details = GetNullableString(el, "details")
                });
            }
        }

        // Seed WSDL templates
        var templatesPath = Path.Combine(_mockDbRoot, "Wsdl", "wsdl-templates.json");
        if (File.Exists(templatesPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(templatesPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _wsdl.WsdlTemplates.Add(new WsdlTemplateEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    Name = el.GetProperty("name").GetString() ?? "",
                    Description = el.GetProperty("description").GetString() ?? "",
                    Content = el.GetProperty("content").GetString() ?? "",
                    ExtendsTemplateId = GetNullableString(el, "extendsTemplateId"),
                    Variables = el.TryGetProperty("variables", out var v) ? v.ToString() : null,
                    CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                    CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                    UpdatedAt = GetNullableString(el, "updatedAt"),
                    UsageCount = el.GetProperty("usageCount").GetInt32()
                });
            }
        }

        await _wsdl.SaveChangesAsync();
    }

    // ──────────────────────────────────────────────
    //  DASHBOARD
    // ──────────────────────────────────────────────

    private async Task SeedDashboardDataAsync()
    {
        // Users
        var usersPath = Path.Combine(_mockDbRoot, "Dashboard", "users.json");
        if (File.Exists(usersPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(usersPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.Users.Add(new UserEntity
                {
                    Name = el.GetProperty("name").GetString() ?? "",
                    Role = el.GetProperty("role").GetString() ?? "User"
                });
            }
        }

        // Health
        var healthPath = Path.Combine(_mockDbRoot, "Dashboard", "dashboard-health.json");
        if (File.Exists(healthPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(healthPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.DashboardHealth.Add(new DashboardHealthEntity
                {
                    Name = el.GetProperty("name").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? ""
                });
            }
        }

        // Metrics
        var metricsPath = Path.Combine(_mockDbRoot, "Dashboard", "dashboard-metrics.json");
        if (File.Exists(metricsPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(metricsPath));
            var metrics = new Dictionary<string, int>
            {
                ["restAppCount"] = doc.RootElement.GetProperty("restAppCount").GetInt32(),
                ["restAppsEnabled"] = doc.RootElement.GetProperty("restAppsEnabled").GetInt32(),
                ["soapAppCount"] = doc.RootElement.GetProperty("soapAppCount").GetInt32(),
                ["soapAppsEnabled"] = doc.RootElement.GetProperty("soapAppsEnabled").GetInt32(),
                ["testSuiteCount"] = doc.RootElement.GetProperty("testSuiteCount").GetInt32(),
                ["passingCases"] = doc.RootElement.GetProperty("passingCases").GetInt32(),
                ["totalCases"] = doc.RootElement.GetProperty("totalCases").GetInt32(),
            };
            var metricId = 0;
            foreach (var kv in metrics)
            {
                metricId++;
                _dashboard.DashboardMetrics.Add(new DashboardMetricEntity
                {
                    Id = $"m-{metricId}",
                    Name = kv.Key,
                    Value = kv.Value
                });
            }
        }

        // User activity
        var activityPath = Path.Combine(_mockDbRoot, "Dashboard", "user-activity.json");
        if (File.Exists(activityPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(activityPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.UserActivity.Add(new UserActivityEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    UserName = el.GetProperty("userName").GetString() ?? "",
                    Action = el.GetProperty("action").GetString() ?? "",
                    Timestamp = el.GetProperty("timestamp").GetString() ?? ""
                });
            }
        }

        // Service uptime
        var uptimePath = Path.Combine(_mockDbRoot, "Dashboard", "service-uptime.json");
        if (File.Exists(uptimePath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(uptimePath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.ServiceUptime.Add(new ServiceUptimeEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    ServiceName = el.GetProperty("serviceName").GetString() ?? "",
                    Timestamp = el.GetProperty("timestamp").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? ""
                });
            }
        }

        // Test suites
        var suitesPath = Path.Combine(_mockDbRoot, "Dashboard", "dashboard-test-suites.json");
        if (File.Exists(suitesPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(suitesPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.TestSuites.Add(new TestSuiteEntity
                {
                    Name = el.GetProperty("name").GetString() ?? "",
                    TotalCases = el.GetProperty("totalCases").GetInt32(),
                    PassingCases = el.GetProperty("passingCases").GetInt32(),
                    TotalFiles = el.GetProperty("totalFiles").GetInt32()
                });
            }
        }

        // Test suite history
        var historyPath = Path.Combine(_mockDbRoot, "Dashboard", "test-suite-history.json");
        if (File.Exists(historyPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(historyPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.TestSuiteHistory.Add(new TestSuiteHistoryEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    SuiteName = el.GetProperty("suiteName").GetString() ?? "",
                    ExecutedAt = el.GetProperty("executedAt").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "",
                    TotalCases = el.GetProperty("totalCases").GetInt32(),
                    PassingCases = el.GetProperty("passingCases").GetInt32(),
                    DurationMs = el.GetProperty("durationMs").GetInt32()
                });
            }
        }

        // Recent activity
        var recentPath = Path.Combine(_mockDbRoot, "Dashboard", "dashboard-recent-activity.json");
        if (File.Exists(recentPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(recentPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                _dashboard.RecentActivity.Add(new RecentActivityEntity
                {
                    User = el.GetProperty("user").GetString() ?? "",
                    Action = el.GetProperty("action").GetString() ?? "",
                    TimeAgo = el.GetProperty("timeAgo").GetString() ?? ""
                });
            }
        }

        await _dashboard.SaveChangesAsync();
    }

    // ──────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────

    private static string? GetNullableString(JsonElement el, string propertyName)
    {
        if (!el.TryGetProperty(propertyName, out var prop) || prop.ValueKind == JsonValueKind.Null)
            return null;
        return prop.GetString();
    }

    /// <summary>
    /// Maps the mock_db auth type string (e.g. "api-key", "basic") to the database
    /// enum name (e.g. "ApiKey", "Basic") used in the schema.
    /// </summary>
    private static string MapAuthType(string jsonAuthType)
    {
        return jsonAuthType.ToLowerInvariant() switch
        {
            "none" => "None",
            "basic" => "Basic",
            "api-key" => "ApiKey",
            "bearer" => "Bearer",
            "ntlm" => "Ntlm",
            _ => "None"
        };
    }
}