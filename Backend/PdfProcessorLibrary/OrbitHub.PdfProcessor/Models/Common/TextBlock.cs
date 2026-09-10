namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record TextBlock(string Text, BoundingBox Bounds, int PageNumber);