using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

public sealed class CreateDirectExecutionAuditRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<CreateDirectExecutionAuditOutput>> ExecuteAsync(
        CreateDirectExecutionAuditInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<CreateDirectExecutionAuditOutput>(
                "usp_CreateDirectExecutionAudit",
                new DataParameter("@Name", input.Name),
                new DataParameter("@ExecutedBy", input.ExecutedBy))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<CreateDirectExecutionAuditOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<CreateDirectExecutionAuditOutput>.CreateFailure(ex);
        }
    }
}