using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

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