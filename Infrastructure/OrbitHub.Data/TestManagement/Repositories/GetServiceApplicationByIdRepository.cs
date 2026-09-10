using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class GetServiceApplicationByIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceApplicationByIdOutput>> ExecuteAsync(
        GetServiceApplicationByIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceApplicationByIdOutput>(
                "usp_GetServiceApplicationById",
                new DataParameter("@Id", input.Id))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceApplicationByIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceApplicationByIdOutput>.CreateFailure(ex);
        }
    }
}