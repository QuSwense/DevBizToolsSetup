using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

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