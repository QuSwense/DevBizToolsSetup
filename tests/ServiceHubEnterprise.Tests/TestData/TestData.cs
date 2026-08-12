using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.Tests.Builders;

/// <summary>
/// Central factory for building test entities/fixtures used across store and page tests.
/// </summary>
public static class TestData
{
    // ── SOAP application ──

    public static SoapApp SoapApp(
        string id = "app-1",
        string name = "BillingService",
        string baseUrl = "https://soap.example.com/billing",
        string wsdlPath = "?wsdl",
        string description = "Billing SOAP service",
        AppStatus status = AppStatus.Enabled,
        string createdBy = "Priya Sharma",
        DateTime? createdAt = null,
        string? updatedBy = "Rahul Verma",
        DateTime? updatedAt = null,
        SoapAuthConfig? auth = null,
        SoapApiEntry[]? apis = null)
        => new(
            id,
            name,
            baseUrl,
            wsdlPath,
            description,
            status,
            createdBy,
            createdAt ?? new DateTime(2024, 1, 15),
            updatedBy,
            updatedAt ?? new DateTime(2024, 6, 1),
            auth ?? Auth(),
            apis ?? [Api("GetInvoice")]);

    public static SoapAuthConfig Auth(
        AuthType type = AuthType.None,
        string? username = null,
        string? password = null,
        string? keyName = null,
        string? keyValue = null,
        string? token = null,
        string? domain = null)
        => new()
        {
            Type = type,
            Username = username,
            Password = password,
            KeyName = keyName,
            KeyValue = keyValue,
            Token = token,
            Domain = domain
        };

    public static SoapApiEntry Api(string name, string description = "")
        => new() { Name = name, Description = description };

    // ── WSDL sync ──

    public static WsdlSyncRecord WsdlRecord(
        string id = "rec-1",
        string appId = "app-1",
        string appName = "BillingService",
        string sourceType = "url",
        string sourceUrl = "https://soap.example.com/billing?wsdl",
        string uploadedBy = "Priya Sharma",
        string uploadedAt = "2024-06-01",
        string status = "synced",
        string wsdlContent = "",
        string wsdlContentKey = "",
        int versionCount = 1)
        => new()
        {
            Id = id,
            AppId = appId,
            AppName = appName,
            SourceType = sourceType,
            SourceUrl = sourceUrl,
            UploadedBy = uploadedBy,
            UploadedAt = uploadedAt,
            Status = status,
            WsdlContent = wsdlContent,
            WsdlContentKey = wsdlContentKey,
            VersionCount = versionCount
        };

    public static WsdlVersionEntry WsdlVersion(
        string id = "ver-1",
        string syncRecordId = "rec-1",
        int versionNumber = 1,
        string label = "v1",
        string uploadedBy = "Priya Sharma",
        string uploadedAt = "2024-06-01",
        string status = "active",
        string notes = "")
        => new()
        {
            Id = id,
            SyncRecordId = syncRecordId,
            VersionNumber = versionNumber,
            Label = label,
            UploadedBy = uploadedBy,
            UploadedAt = uploadedAt,
            Status = status,
            Notes = notes
        };

    public static WsdlTemplate Template(
        string id = "tpl-1",
        string name = "Standard",
        string description = "",
        string content = "Hello {{name}}",
        string? extendsTemplateId = null,
        string? extendsTemplateName = null,
        string[]? variables = null,
        string createdBy = "Priya Sharma",
        string createdAt = "2024-06-01",
        string? updatedBy = null,
        string? updatedAt = null)
        => new()
        {
            Id = id,
            Name = name,
            Description = description,
            Content = content,
            ExtendsTemplateId = extendsTemplateId,
            ExtendsTemplateName = extendsTemplateName,
            Variables = variables ?? [],
            CreatedBy = createdBy,
            CreatedAt = createdAt,
            UpdatedBy = updatedBy,
            UpdatedAt = updatedAt
        };

    // ── Executions ──

    public static SoapExecution Execution(
        string id = "ex-1",
        string appName = "BillingService",
        string appType = "soap",
        string fileName = "GetInvoice.xml",
        string status = "passed",
        string executedAt = "2024-06-01 10:00:00",
        long durationMs = 120,
        string triggeredBy = "Priya Sharma")
        => new(id, appName, appType, fileName, status, executedAt, durationMs, triggeredBy);
}
