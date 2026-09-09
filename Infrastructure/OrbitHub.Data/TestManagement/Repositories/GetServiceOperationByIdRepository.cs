using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class GetServiceOperationByIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceOperationByIdOutput>> ExecuteAsync(
        GetServiceOperationByIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceOperationByIdOutput>(
                "usp_GetServiceOperationById",
                new DataParameter("@Id", input.Id))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceOperationByIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceOperationByIdOutput>.CreateFailure(ex);
        }
    }
}