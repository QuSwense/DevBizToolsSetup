namespace ServiceHub.SoapEngine.Core.Services;

using System.IO.Compression;

/// <summary>
/// Provides GZip stream and byte array compression and decompression services
/// for XML payloads, request/response files, and response attachments.
/// </summary>
public class SoapFileCompressor
{
    /// <summary>
    /// Compresses uncompressed raw byte data using GZip (Optimal compression level).
    /// </summary>
    /// <param name="rawData">The uncompressed byte array payload.</param>
    /// <returns>A compressed GZip byte array.</returns>
    public byte[] Compress(byte[] rawData)
    {
        if (rawData is null || rawData.Length == 0)
        {
            return [];
        }

        using var memoryStream = new MemoryStream();
        using (var gzipStream = new GZipStream(memoryStream, CompressionLevel.Optimal, leaveOpen: true))
        {
            gzipStream.Write(rawData, 0, rawData.Length);
        }

        return memoryStream.ToArray();
    }

    /// <summary>
    /// Compresses an uncompressed input stream into a GZip compressed byte array.
    /// </summary>
    /// <param name="inputStream">The readable input stream containing raw data.</param>
    /// <returns>A compressed GZip byte array.</returns>
    public byte[] Compress(Stream inputStream)
    {
        if (inputStream is null || !inputStream.CanRead)
        {
            return [];
        }

        using var memoryStream = new MemoryStream();
        using (var gzipStream = new GZipStream(memoryStream, CompressionLevel.Optimal, leaveOpen: true))
        {
            inputStream.CopyTo(gzipStream);
        }

        return memoryStream.ToArray();
    }

    /// <summary>
    /// Decompresses a GZip compressed byte array back to its original uncompressed raw bytes.
    /// </summary>
    /// <param name="compressedData">The GZip compressed byte array.</param>
    /// <returns>An uncompressed raw byte array.</returns>
    public byte[] Decompress(byte[] compressedData)
    {
        if (compressedData is null || compressedData.Length == 0)
        {
            return [];
        }

        using var compressedStream = new MemoryStream(compressedData);
        using var gzipStream = new GZipStream(compressedStream, CompressionMode.Decompress);
        using var resultStream = new MemoryStream();

        gzipStream.CopyTo(resultStream);
        return resultStream.ToArray();
    }

    /// <summary>
    /// Asynchronously decompresses a GZip compressed byte array back into an uncompressed memory stream.
    /// </summary>
    /// <param name="compressedData">The GZip compressed byte array.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A readable <see cref="MemoryStream"/> containing uncompressed bytes positioned at 0.</returns>
    public async Task<MemoryStream> DecompressToStreamAsync(
        byte[] compressedData,
        CancellationToken cancellationToken = default)
    {
        var resultStream = new MemoryStream();

        if (compressedData is null || compressedData.Length == 0)
        {
            return resultStream;
        }

        using var compressedStream = new MemoryStream(compressedData);
        await using var gzipStream = new GZipStream(compressedStream, CompressionMode.Decompress);

        await gzipStream.CopyToAsync(resultStream, cancellationToken);
        resultStream.Position = 0;

        return resultStream;
    }
}