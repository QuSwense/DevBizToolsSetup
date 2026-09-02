namespace MockOAuthSoapService.Services;

using System.Security.Cryptography;

using MockOAuthSoapService.Models;

public class DocumentSoapService : IDocumentSoapService
{
    public UploadDocumentResponse UploadDocument(UploadDocumentRequest request)
    {
        string docId = $"DOC-{Guid.NewGuid():N}"[..12].ToUpper();
        byte[] hash = SHA256.HashData(request.ContentBytes);

        return new UploadDocumentResponse
        {
            DocumentId = docId,
            FileHash = Convert.ToHexString(hash),
            SizeBytes = request.ContentBytes.Length,
            UploadedAt = DateTime.UtcNow
        };
    }

    public GetDocumentResponse GetDocument(GetDocumentRequest request)
    {
        byte[] dummyBytes = "Sample PDF Content Stream"u8.ToArray();

        return new GetDocumentResponse
        {
            DocumentId = request.DocumentId,
            Title = "Confidential_Audit_Report.pdf",
            SecurityLevel = EDocumentSecurityLevel.Confidential,
            ContentBytes = dummyBytes
        };
    }
}