using LinqToDB.Data;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class GetServiceAppAuthenticationByAppIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceAppAuthenticationByAppIdOutput>> ExecuteAsync(
        GetServiceAppAuthenticationByAppIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceAppAuthenticationByAppIdOutput>(
                "usp_GetServiceAppAuthenticationByAppId",
                new DataParameter("@ServiceApplicationId", input.ServiceApplicationId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceAppAuthenticationByAppIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceAppAuthenticationByAppIdOutput>.CreateFailure(ex);
        }
    }
}