namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record TextWord(
    string Text,
    BoundingBox Bounds,
    int PageNumber
);