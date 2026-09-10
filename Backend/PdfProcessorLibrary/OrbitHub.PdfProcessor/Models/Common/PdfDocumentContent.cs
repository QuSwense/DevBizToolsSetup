public record PdfDocumentContent(
    IReadOnlyList<PdfFormField> FormFields,
    IReadOnlyList<PageTextContent> Pages
);