using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class GetDirectExecutionAuditResponseFileLinksByAuditIdRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<List<GetDirectExecutionAuditResponseFileLinksByAuditIdOutput>>> ExecuteAsync(
        GetDirectExecutionAuditResponseFileLinksByAuditIdInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetDirectExecutionAuditResponseFileLinksByAuditIdOutput>(
                "usp_GetDirectExecutionAuditResponseFileLinksByAuditId",
                new DataParameter("@DirectExecutionAuditId", input.DirectExecutionAuditId))
            .ConfigureAwait(false)).ToList();

return RepositoryResult<List<GetDirectExecutionAuditResponseFileLinksByAuditIdOutput>>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<List<GetDirectExecutionAuditResponseFileLinksByAuditIdOutput>>.CreateFailure(ex);
        }
    }
}