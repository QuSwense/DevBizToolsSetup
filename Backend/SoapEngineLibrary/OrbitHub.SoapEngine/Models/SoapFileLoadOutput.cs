namespace OrbitHub.SoapEngine.Models;

public class SoapFileLoadOutput
{
    public int ServiceOperationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool SimilarBlobFound { get; set; } = false;
    public bool SameNameExists { get; set; } = false;
}