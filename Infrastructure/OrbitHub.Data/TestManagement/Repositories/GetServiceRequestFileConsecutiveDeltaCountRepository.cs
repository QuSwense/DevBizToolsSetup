using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class GetServiceRequestFileConsecutiveDeltaCountRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceRequestFileConsecutiveDeltaCountOutput>> ExecuteAsync(
        GetServiceRequestFileConsecutiveDeltaCountInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceRequestFileConsecutiveDeltaCountOutput>(
                "usp_GetServiceRequestFileConsecutiveDeltaCount",
                new DataParameter("@RequestFileId", input.RequestFileId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceRequestFileConsecutiveDeltaCountOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceRequestFileConsecutiveDeltaCountOutput>.CreateFailure(ex);
        }
    }
}