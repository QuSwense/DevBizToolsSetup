using System;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for registering a new SOAP application.
/// </summary>
public class RegisterApplicationInput
{
    public required string AppName { get; set; }
    public required string BaseUrl { get; set; }
    public string? WsdlRelativeUrl { get; set; }
    public string? HealthcheckRelativeUrl { get; set; }
    public string? Description { get; set; }
    public required string CreatedBy { get; set; }
    public Stream? DirectWsdlStream { get; set; }
}