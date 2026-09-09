using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

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