using OrbitHub.PdfProcessor.Core.Models.Fields;

namespace OrbitHub.PdfProcessor.Core.Models.Common;

public record PdfDocumentContent(
    IReadOnlyList<PdfFormField> FormFields,
    IReadOnlyList<PageTextContent> Pages
);