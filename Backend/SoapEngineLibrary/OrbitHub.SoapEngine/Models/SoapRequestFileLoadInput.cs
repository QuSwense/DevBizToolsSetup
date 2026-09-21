using System;
using OrbitHub.GenericModels.Models;

namespace OrbitHub.SoapEngine.Models;

public class SoapRequestFileLoadInput : AuditableEntityModel
{
    public string Name { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool CheckSimilarBlob { get; set; } = false;
    public bool OverwriteExistingByName { get; set; } = false;
}
