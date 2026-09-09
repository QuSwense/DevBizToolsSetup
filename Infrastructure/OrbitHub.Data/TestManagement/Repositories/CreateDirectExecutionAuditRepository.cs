using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

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