using OrbitHub.SoapApplications.Core.Enums;

namespace OrbitHub.SoapApplications.Models;

public record SoapAppModel(string Id, string Name, string BaseUrl, string WsdlPath, string Description, EAppStatus Status, string CreatedBy, DateTime CreatedAt, string? UpdatedBy, DateTime? UpdatedAt, SoapAuthConfigModel Auth, SoapApiEntryModel[] Apis);
