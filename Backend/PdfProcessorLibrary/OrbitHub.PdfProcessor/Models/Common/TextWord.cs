using PdfProcessor.Models.Common;

public record TextWord(
    string Text,
    BoundingBox Bounds,
    int PageNumber
);