namespace PdfProcessor.Models.Common;

public record TextBlock(string Text, BoundingBox Bounds, int PageNumber);