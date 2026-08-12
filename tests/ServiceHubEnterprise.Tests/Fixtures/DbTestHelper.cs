using System.Data.Common;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.SqlServer.Storage.Internal;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Tests.Fixtures;

/// <summary>
/// Creates disposable IServiceProvider instances with in-memory SQLite databases
/// seeded from TempMockDb JSON files. Keeps the underlying SQLite connection open
/// for the lifetime of the helper so all DbContexts share the same in-memory database.
/// </summary>
public sealed class DbTestHelper : IDisposable
{
    private readonly DbConnection _connection;
    private readonly ServiceProvider _serviceProvider;

    public IServiceProvider ServiceProvider => _serviceProvider;

    /// <summary>
    /// Initializes the in-memory database, runs schema.sql, and optionally seeds
    /// the <c>SoapApps</c> / <c>SoapApis</c> tables from a JSON file.
    /// </summary>
    public DbTestHelper(string schemaSql, TempMockDb tempDb, bool seedSoap = false, bool seedWsdl = false)
    {
        _connection = null!;
        _connection.Open();

        // Create schema
        using var cmd = _connection.CreateCommand();
        cmd.CommandText = schemaSql;
        cmd.ExecuteNonQuery();

        var services = new ServiceCollection();
        services.AddDbContext<SoapDbContext>(opts => opts.UseSqlServer(_connection));
        services.AddDbContext<WsdlDbContext>(opts => opts.UseSqlServer(_connection));
        services.AddSingleton<IConfiguration>(tempDb.BuildConfiguration());

        _serviceProvider = services.BuildServiceProvider();

        if (seedSoap)
            SeedSoap(tempDb);
        if (seedWsdl)
            SeedWsdl(tempDb);
    }

    private void SeedSoap(TempMockDb tempDb)
    {
        var soapAppsPath = Path.Combine(tempDb.Path, "Soap", "soap-apps.json");
        if (!File.Exists(soapAppsPath)) return;

        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();

        using var doc = JsonDocument.Parse(File.ReadAllText(soapAppsPath));
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            var auth = el.GetProperty("auth");
            var authTypeStr = auth.GetProperty("type").GetString() ?? "none";
            var authType = authTypeStr switch
            {
                "basic" => "Basic",
                "api-key" => "ApiKey",
                "bearer" => "Bearer",
                "ntlm" => "Ntlm",
                _ => "None"
            };

            var entity = new SoapAppEntity
            {
                Id = el.GetProperty("id").GetString() ?? "",
                Name = el.GetProperty("name").GetString() ?? "",
                BaseUrl = el.GetProperty("baseUrl").GetString() ?? "",
                WsdlPath = el.GetProperty("wsdlPath").GetString() ?? "",
                Description = el.GetProperty("description").GetString() ?? "",
                Status = el.GetProperty("status").GetString() ?? "enabled",
                CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                AuthType = authType,
                AuthUsername = auth.TryGetProperty("username", out var u) ? u.GetString() : null,
                AuthPassword = auth.TryGetProperty("password", out var p) ? p.GetString() : null,
                AuthKeyName = auth.TryGetProperty("keyName", out var kn) ? kn.GetString() : null,
                AuthKeyValue = auth.TryGetProperty("keyValue", out var kv) ? kv.GetString() : null,
                AuthToken = auth.TryGetProperty("token", out var t) ? t.GetString() : null,
                AuthDomain = auth.TryGetProperty("domain", out var d) ? d.GetString() : null,
                UpdatedBy = el.TryGetProperty("updatedBy", out var ub) ? ub.GetString() : null,
                UpdatedAt = el.TryGetProperty("updatedAt", out var ua) ? ua.GetString() : null,
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

            db.SoapApps.Add(entity);
        }

        db.SaveChanges();
    }

    private void SeedWsdl(TempMockDb tempDb)
    {
        var recordsPath = Path.Combine(tempDb.Path, "Wsdl", "wsdl-records.json");
        var templatesPath = Path.Combine(tempDb.Path, "Wsdl", "wsdl-templates.json");
        var versionsPath = Path.Combine(tempDb.Path, "Wsdl", "wsdl-versions.json");
        var historyPath = Path.Combine(tempDb.Path, "Wsdl", "wsdl-sync-history.json");

        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        // Seed records
        if (File.Exists(recordsPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(recordsPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                db.WsdlRecords.Add(new WsdlRecordEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    AppId = el.GetProperty("appId").GetString() ?? "",
                    AppName = el.GetProperty("appName").GetString() ?? "",
                    SourceType = el.GetProperty("sourceType").GetString() ?? "url",
                    SourceUrl = el.GetProperty("sourceUrl").GetString() ?? "",
                    UploadedBy = el.GetProperty("uploadedBy").GetString() ?? "",
                    UploadedAt = el.GetProperty("uploadedAt").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "synced",
                });
            }
        }

        // Seed templates
        if (File.Exists(templatesPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(templatesPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                db.WsdlTemplates.Add(new WsdlTemplateEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    Name = el.GetProperty("name").GetString() ?? "",
                    Description = el.GetProperty("description").GetString() ?? "",
                    Content = el.GetProperty("content").GetString() ?? "",
                    ExtendsTemplateId = el.TryGetProperty("extendsTemplateId", out var eti) ? eti.GetString() : null,
                    Variables = el.TryGetProperty("variables", out var v) ? v.ToString() : null,
                    CreatedBy = el.GetProperty("createdBy").GetString() ?? "",
                    CreatedAt = el.GetProperty("createdAt").GetString() ?? "",
                    UpdatedAt = el.TryGetProperty("updatedAt", out var ua) ? ua.GetString() : null,
                });
            }
        }

        // Seed versions
        if (File.Exists(versionsPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(versionsPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                db.WsdlVersions.Add(new WsdlVersionEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    SyncRecordId = el.GetProperty("syncRecordId").GetString() ?? "",
                    VersionNumber = el.TryGetProperty("versionNumber", out var vn) ? vn.GetInt32() : 1,
                    Label = el.TryGetProperty("label", out var lbl) ? lbl.GetString() ?? "" : "",
                    UploadedBy = el.TryGetProperty("uploadedBy", out var ub) ? ub.GetString() ?? "" : "",
                    UploadedAt = el.TryGetProperty("uploadedAt", out var ua) ? ua.GetString() ?? "" : "",
                    Status = el.TryGetProperty("status", out var st) ? st.GetString() ?? "active" : "active",
                    Notes = el.TryGetProperty("notes", out var n) ? n.GetString() : null,
                    Content = el.TryGetProperty("content", out var c) ? c.GetString() ?? "" : "",
                });
            }
        }

        // Seed sync history
        if (File.Exists(historyPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(historyPath));
            foreach (var el in doc.RootElement.EnumerateArray())
            {
                db.WsdlSyncHistory.Add(new WsdlSyncHistoryEntity
                {
                    Id = el.GetProperty("id").GetString() ?? "",
                    AppId = el.GetProperty("appId").GetString() ?? "",
                    AppName = el.GetProperty("appName").GetString() ?? "",
                    SyncRecordId = el.GetProperty("syncRecordId").GetString() ?? "",
                    Date = el.GetProperty("date").GetString() ?? "",
                    Status = el.GetProperty("status").GetString() ?? "",
                });
            }
        }

        db.SaveChanges();
    }

    public void Dispose()
    {
        _serviceProvider.Dispose();
        _connection.Close();
        _connection.Dispose();
    }
}