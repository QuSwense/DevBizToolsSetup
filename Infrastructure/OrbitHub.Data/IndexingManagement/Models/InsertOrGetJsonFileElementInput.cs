namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertOrGetJsonFileElementInput
{
    public string ElementName { get; set; } = default!;
    public string JsonPath { get; set; } = default!;
    public string? ValueType { get; set; }
    public string? UserId { get; set; }
}