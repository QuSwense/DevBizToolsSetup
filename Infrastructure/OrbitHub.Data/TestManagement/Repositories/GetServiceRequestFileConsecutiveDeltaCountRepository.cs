using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

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