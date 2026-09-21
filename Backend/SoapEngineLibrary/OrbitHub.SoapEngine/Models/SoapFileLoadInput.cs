using System;
using OrbitHub.GenericModels.Models;

namespace OrbitHub.SoapEngine.Models;

public class SoapFileLoadInput : AuditableEntityModel
{
    public int ServiceOperationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool CheckSimilarBlob { get; set; } = false;
    public bool OverwriteExistingByName { get; set; } = false;
}
