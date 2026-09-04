namespace ServiceHub.SoapEngine.Core.Services;

using System.Text;
using DiffPlex;
using DiffPlex.DiffBuilder;
using DiffPlex.DiffBuilder.Model;
using ServiceHub.SoapEngine.Core.Data.Generated;

/// <summary>
/// Provides backward diff generation and historical payload reconstruction services for XML/SOAP files using DiffPlex.
/// </summary>
public class SoapFileDeltaPatcher(SoapFileCompressor compressor)
{
    private readonly ISideBySideDiffBuilder _diffBuilder = new SideBySideDiffBuilder(new Differ());

    /// <summary>
    /// Generates a compressed backward patch from the new payload to an older baseline payload.
    /// Patch direction: New Version -> Old Version.
    /// </summary>
    /// <param name="newRawBytes">The uncompressed bytes of the new version.</param>
    /// <param name="oldRawBytes">The uncompressed bytes of the previous version.</param>
    /// <returns>A GZip compressed byte array containing the backward line diff payload.</returns>
    public byte[] CreateBackwardDiff(byte[] newRawBytes, byte[] oldRawBytes)
    {
        string newText = Encoding.UTF8.GetString(newRawBytes);
        string oldText = Encoding.UTF8.GetString(oldRawBytes);

        var diffModel = _diffBuilder.BuildDiffModel(newText, oldText);
        string serializedPatch = SerializeSideBySideDiff(diffModel);

        byte[] patchBytes = Encoding.UTF8.GetBytes(serializedPatch);
        return compressor.Compress(patchBytes);
    }

    /// <summary>
    /// Reconstructs an older historical payload version by applying a backward patch to a newer baseline version payload.
    /// </summary>
    /// <param name="newerRawBytes">The uncompressed bytes of the newer reference version.</param>
    /// <param name="compressedDiffData">The GZip compressed backward patch byte array.</param>
    /// <returns>The uncompressed byte array of the target historical version.</returns>
    public byte[] ApplyBackwardDiff(byte[] newerRawBytes, byte[] compressedDiffData)
    {
        byte[] patchBytes = compressor.Decompress(compressedDiffData);
        string serializedPatch = Encoding.UTF8.GetString(patchBytes);

        string newerText = Encoding.UTF8.GetString(newerRawBytes);
        string reconstructedOldText = ReconstructOldFromPatch(newerText, serializedPatch);

        return Encoding.UTF8.GetBytes(reconstructedOldText);
    }

    #region Helper Serialization & Reconstruction Logic

    private static string SerializeSideBySideDiff(SideBySideDiffModel diff)
    {
        var sb = new StringBuilder();

        int maxLines = Math.Max(diff.OldText.Lines.Count, diff.NewText.Lines.Count);
        for (int i = 0; i < maxLines; i++)
        {
            var oldLine = i < diff.OldText.Lines.Count ? diff.OldText.Lines[i] : null;
            var newLine = i < diff.NewText.Lines.Count ? diff.NewText.Lines[i] : null;

            sb.Append(oldLine?.Type ?? ChangeType.Unchanged).Append('|');
            sb.Append(newLine?.Type ?? ChangeType.Unchanged).Append('|');
            sb.Append(oldLine?.Text ?? string.Empty).Append('|');
            sb.AppendLine(newLine?.Text ?? string.Empty);
        }

        return sb.ToString();
    }

    private static string ReconstructOldFromPatch(string newText, string serializedPatch)
    {
        var sb = new StringBuilder();
        using var reader = new StringReader(serializedPatch);

        string? line;
        while ((line = reader.ReadLine()) is not null)
        {
            var parts = line.Split('|', 4);
            if (parts.Length < 4)
            {
                continue;
            }

            var oldType = Enum.Parse<ChangeType>(parts[0]);
            string oldLineText = parts[2];

            if (oldType != ChangeType.Deleted && oldType != ChangeType.Imaginary)
            {
                sb.AppendLine(oldLineText);
            }
            else if (oldType == ChangeType.Inserted || oldType == ChangeType.Modified)
            {
                sb.AppendLine(oldLineText);
            }
        }

        return sb.ToString().TrimEnd('\r', '\n');
    }

    /// <summary>
    /// Reconstructs a targeted historical payload version from a sequence of history records 
    /// and the current active file payload.
    /// </summary>
    public byte[] ReconstructHistoricalVersion(
        SoapRequestFile currentActiveFile,
        List<SoapRequestFileHistory> historyChain,
        int targetHistoryId)
    {
        byte[] currentBytes = compressor.Decompress(currentActiveFile.FileData);

        // Order history from newest to oldest
        var orderedHistory = historyChain.OrderByDescending(h => h.CreatedAt).ToList();

        foreach (var historyRecord in orderedHistory)
        {
            if (historyRecord.FileData != null)
            {
                // Found full snapshot anchor - reset baseline bytes
                currentBytes = compressor.Decompress(historyRecord.FileData);
            }
            else if (historyRecord.DiffData != null)
            {
                // Apply backward patch
                currentBytes = ApplyBackwardDiff(currentBytes, historyRecord.DiffData);
            }

            // Stop when we reach the target version
            if (historyRecord.Id == targetHistoryId)
            {
                break;
            }
        }

        return currentBytes;
    }

    #endregion
}