using LinqToDB.Data;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class GetDirectExecutionAuditByIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetDirectExecutionAuditByIdOutput>> ExecuteAsync(
        GetDirectExecutionAuditByIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetDirectExecutionAuditByIdOutput>(
                "usp_GetDirectExecutionAuditById",
                new DataParameter("@AuditId", input.AuditId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetDirectExecutionAuditByIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetDirectExecutionAuditByIdOutput>.CreateFailure(ex);
        }
    }
}