namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record TextLine(
    int LineNumber,
    string Text,
    BoundingBox Bounds,
    int PageNumber,
    IReadOnlyList<TextWord> Words
);