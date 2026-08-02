namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// A SOAP request file associated with an application (from mock_db/Soap/Request/request-files.json).
/// </summary>
public record SoapRequestFile(
    string FileName,
    string AppName,
    string ApiPath,
    string Verb,
    string Description,
    string Status,
    string CreatedBy,
    DateTime CreatedAt,
    string? UpdatedBy,
    DateTime? UpdatedAt,
    string? Content = null,
    string[]? TestCaseIds = null);
