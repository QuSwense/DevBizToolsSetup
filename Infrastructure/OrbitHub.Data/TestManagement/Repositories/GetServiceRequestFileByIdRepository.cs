using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class GetServiceRequestFileByIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceRequestFileByIdOutput>> ExecuteAsync(
        GetServiceRequestFileByIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceRequestFileByIdOutput>(
                "usp_GetServiceRequestFileById",
                new DataParameter("@Id", input.Id))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceRequestFileByIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceRequestFileByIdOutput>.CreateFailure(ex);
        }
    }
}