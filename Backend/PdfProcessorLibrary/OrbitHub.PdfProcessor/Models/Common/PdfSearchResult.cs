namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record PdfSearchResult(
    string MatchedTerm,
    int PageNumber,
    BoundingBox Bounds,
    string SurroundingSnippet
);