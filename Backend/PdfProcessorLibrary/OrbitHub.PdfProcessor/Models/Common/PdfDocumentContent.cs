using PdfProcessor.Models.Fields;

public record PdfDocumentContent(
    IReadOnlyList<PdfFormField> FormFields,
    IReadOnlyList<PageTextContent> Pages
);