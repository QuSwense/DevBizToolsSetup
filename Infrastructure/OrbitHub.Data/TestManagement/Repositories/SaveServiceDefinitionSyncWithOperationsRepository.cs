using LinqToDB.Data;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class SaveServiceDefinitionSyncWithOperationsRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<SaveServiceDefinitionSyncWithOperationsOutput>> ExecuteAsync(
        SaveServiceDefinitionSyncWithOperationsInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<SaveServiceDefinitionSyncWithOperationsOutput>(
                "usp_SaveServiceDefinitionSyncWithOperations",
                new DataParameter("@ServiceApplicationId", input.ServiceApplicationId),
                new DataParameter("@DefinitionUrl", input.DefinitionUrl),
                new DataParameter("@CompressedContent", input.CompressedContent),
                new DataParameter("@UncompressedSizeBytes", input.UncompressedSizeBytes),
                new DataParameter("@CompressionAlgorithmType", input.CompressionAlgorithmType),
                new DataParameter("@ContentHash", input.ContentHash),
                new DataParameter("@UserId", input.UserId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<SaveServiceDefinitionSyncWithOperationsOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<SaveServiceDefinitionSyncWithOperationsOutput>.CreateFailure(ex);
        }
    }
}