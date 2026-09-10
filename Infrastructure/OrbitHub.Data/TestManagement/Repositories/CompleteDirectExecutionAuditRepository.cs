using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class CompleteDirectExecutionAuditRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult> ExecuteAsync(
        CompleteDirectExecutionAuditInput input,
        CancellationToken ct = default)
    {
        try
        {
            await ctx.ExecuteAsync(
                "usp_CompleteDirectExecutionAudit",
                new DataParameter("@AuditId", input.AuditId),
                new DataParameter("@ExecutionStatus", input.ExecutionStatus),
                new DataParameter("@ExecutionDetails", input.ExecutionDetails))
            .ConfigureAwait(false);

            return RepositoryResult.CreateSuccess();
        }
        catch (Exception ex)
        {
            return RepositoryResult.CreateFailure(ex);
        }
    }
}