using LinqToDB.Data;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class GetServiceDefinitionSyncLatestVersionRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceDefinitionSyncLatestVersionOutput>> ExecuteAsync(
        GetServiceDefinitionSyncLatestVersionInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceDefinitionSyncLatestVersionOutput>(
                "usp_GetServiceDefinitionSyncLatestVersion",
                new DataParameter("@ServiceApplicationId", input.ServiceApplicationId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceDefinitionSyncLatestVersionOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceDefinitionSyncLatestVersionOutput>.CreateFailure(ex);
        }
    }
}