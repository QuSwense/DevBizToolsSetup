namespace MockOAuthSoapService.Services;

using System.ServiceModel;
using MockOAuthSoapService.Models;

[ServiceContract(Namespace = "http://servicehub.org/document/soap")]
public interface IDocumentSoapService
{
    [OperationContract]
    UploadDocumentResponse UploadDocument(UploadDocumentRequest request);

    [OperationContract]
    GetDocumentResponse GetDocument(GetDocumentRequest request);
}