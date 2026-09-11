namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record PageTextContent(
    int PageNumber,
    string FullText,
    IReadOnlyList<TextLine> Lines,
    IReadOnlyList<TextWord> Words
);