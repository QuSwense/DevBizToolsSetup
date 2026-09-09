namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the encryption algorithms used for securing authentication credentials.
/// Maps to CK_ServiceAppAuthentications_EncryptionAlgorithmType: 'AES-GCM', 'RSA', 'None'.
/// </summary>
public enum EEncryptionAlgorithmType
{
    /// <summary>AES-GCM (Advanced Encryption Standard in Galois/Counter Mode) — symmetric encryption.</summary>
    AES_GCM = 0,

    /// <summary>RSA (Rivest–Shamir–Adleman) — asymmetric encryption.</summary>
    RSA = 1,

    /// <summary>No encryption applied.</summary>
    None = 2
}
