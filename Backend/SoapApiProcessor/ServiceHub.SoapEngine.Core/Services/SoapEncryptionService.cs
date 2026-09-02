namespace ServiceHub.SoapEngine.Core.Services;

using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

/// <summary>
/// Provides AES-256-GCM encryption and decryption for sensitive credential payloads.
/// </summary>
public class SoapEncryptionService
{
    private readonly byte[] _key;

    /// <summary>
    /// Initializes encryption with a 256-bit (32-byte) key.
    /// </summary>
    /// <param name="base64Key">A 32-byte key encoded as Base64.</param>
    public SoapEncryptionService(string base64Key)
    {
        if (string.IsNullOrWhiteSpace(base64Key))
        {
            throw new ArgumentException("Encryption key cannot be empty.", nameof(base64Key));
        }

        _key = Convert.FromBase64String(base64Key);
        if (_key.Length != 32)
        {
            throw new ArgumentException("AES-256 encryption key must be exactly 32 bytes (256 bits).", nameof(base64Key));
        }
    }

    /// <summary>
    /// Serializes an object to JSON and encrypts it using AES-GCM.
    /// Returns a Base64-encoded string formatted as: [Nonce (12B)][Tag (16B)][Ciphertext].
    /// </summary>
    public string EncryptObject<T>(T obj)
    {
        var jsonBytes = JsonSerializer.SerializeToUtf8Bytes(obj);

        byte[] nonce = new byte[AesGcm.NonceByteSizes.MaxSize]; // 12 bytes
        RandomNumberGenerator.Fill(nonce);

        byte[] tag = new byte[AesGcm.TagByteSizes.MaxSize]; // 16 bytes
        byte[] cipherText = new byte[jsonBytes.Length];

        using var aesGcm = new AesGcm(_key, AesGcm.TagByteSizes.MaxSize);
        aesGcm.Encrypt(nonce, jsonBytes, cipherText, tag);

        // Combined payload: Nonce + Tag + CipherText
        byte[] payload = new byte[nonce.Length + tag.Length + cipherText.Length];
        Buffer.BlockCopy(nonce, 0, payload, 0, nonce.Length);
        Buffer.BlockCopy(tag, 0, payload, nonce.Length, tag.Length);
        Buffer.BlockCopy(cipherText, 0, payload, nonce.Length + tag.Length, cipherText.Length);

        return Convert.ToBase64String(payload);
    }

    /// <summary>
    /// Decrypts a Base64-encoded payload back into a strongly-typed object.
    /// </summary>
    public T? DecryptObject<T>(string encryptedBase64Payload)
    {
        byte[] payload = Convert.FromBase64String(encryptedBase64Payload);

        int nonceSize = AesGcm.NonceByteSizes.MaxSize; // 12 bytes
        int tagSize = AesGcm.TagByteSizes.MaxSize;     // 16 bytes
        int cipherSize = payload.Length - nonceSize - tagSize;

        if (cipherSize <= 0)
        {
            throw new CryptographicException("Invalid encrypted payload length.");
        }

        byte[] nonce = payload[..nonceSize];
        byte[] tag = payload[nonceSize..(nonceSize + tagSize)];
        byte[] cipherText = payload[(nonceSize + tagSize)..];

        byte[] plaintextBytes = new byte[cipherSize];

        using var aesGcm = new AesGcm(_key, AesGcm.TagByteSizes.MaxSize);
        aesGcm.Decrypt(nonce, cipherText, tag, plaintextBytes);

        return JsonSerializer.Deserialize<T>(plaintextBytes);
    }
}