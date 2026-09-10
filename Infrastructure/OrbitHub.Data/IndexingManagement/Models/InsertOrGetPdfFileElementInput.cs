namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertOrGetPdfFileElementInput
{
    public string ElementName { get; set; } = default!;
    public string ElementType { get; set; } = default!;
    public int PageNumber { get; set; }
    public string BoundingRectangle { get; set; } = default!;
    public string? ValueType { get; set; }
    public string? UserId { get; set; }
}