namespace MockOAuthSoapService.Models;

using System.Runtime.Serialization;

#region Namespace: Document Types (http://servicehub.org/document/types)

[DataContract(Namespace = "http://servicehub.org/document/types")]
public enum EDocumentSecurityLevel
{
    [EnumMember] Public,
    [EnumMember] Internal,
    [EnumMember] Confidential,
    [EnumMember] Restricted
}

[DataContract(Namespace = "http://servicehub.org/document/types")]
public class UploadDocumentRequest
{
    [DataMember(IsRequired = true)] public required string Title { get; set; }
    [DataMember(IsRequired = true)] public required string FileExtension { get; set; }
    [DataMember(IsRequired = true)] public required EDocumentSecurityLevel SecurityLevel { get; set; }
    [DataMember(IsRequired = true)] public required byte[] ContentBytes { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/document/types")]
public class UploadDocumentResponse
{
    [DataMember(IsRequired = true)] public required string DocumentId { get; set; }
    [DataMember(IsRequired = true)] public required string FileHash { get; set; }
    [DataMember] public long SizeBytes { get; set; }
    [DataMember] public DateTime UploadedAt { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/document/types")]
public class GetDocumentRequest
{
    [DataMember(IsRequired = true)] public required string DocumentId { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/document/types")]
public class GetDocumentResponse
{
    [DataMember(IsRequired = true)] public required string DocumentId { get; set; }
    [DataMember(IsRequired = true)] public required string Title { get; set; }
    [DataMember(IsRequired = true)] public required EDocumentSecurityLevel SecurityLevel { get; set; }
    [DataMember] public required byte[] ContentBytes { get; set; }
}

#endregion