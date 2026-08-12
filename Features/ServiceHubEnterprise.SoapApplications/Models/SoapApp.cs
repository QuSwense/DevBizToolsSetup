using ServiceHubEnterprise.SoapApplications.Core.Enums;

namespace ServiceHubEnterprise.SoapApplications.Models;

public record SoapApp(string Id, string Name, string BaseUrl, string WsdlPath, string Description, AppStatus Status, string CreatedBy, DateTime CreatedAt, string? UpdatedBy, DateTime? UpdatedAt, SoapAuthConfig Auth, SoapApiEntry[] Apis);
