using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class UpdateServiceRequestFileWithDeltaChainRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult> ExecuteAsync(
        UpdateServiceRequestFileWithDeltaChainInput input,
        CancellationToken ct = default)
    {
        try
        {
            await ctx.ExecuteAsync(
                "usp_UpdateServiceRequestFileWithDeltaChain",
                new DataParameter("@FileId", input.FileId),
                new DataParameter("@CompressedData", input.CompressedData),
                new DataParameter("@UncompressedSizeBytes", input.UncompressedSizeBytes),
                new DataParameter("@CompressionAlgorithmType", input.CompressionAlgorithmType),
                new DataParameter("@ContentHash", input.ContentHash),
                new DataParameter("@BackwardDiffData", input.BackwardDiffData),
                new DataParameter("@UserId", input.UserId))
            .ConfigureAwait(false);

            return RepositoryResult.CreateSuccess();
        }
        catch (Exception ex)
        {
            return RepositoryResult.CreateFailure(ex);
        }
    }
}