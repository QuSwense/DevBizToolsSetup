using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class CreateDirectExecutionAuditResponseFileLinkRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<CreateDirectExecutionAuditResponseFileLinkOutput>> ExecuteAsync(
        CreateDirectExecutionAuditResponseFileLinkInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<CreateDirectExecutionAuditResponseFileLinkOutput>(
                "usp_CreateDirectExecutionAuditResponseFileLink",
                new DataParameter("@DirectExecutionAuditId", input.DirectExecutionAuditId),
                new DataParameter("@ServiceRequestFileId", input.ServiceRequestFileId),
                new DataParameter("@ExecutionOrder", input.ExecutionOrder),
                new DataParameter("@ExecutedBy", input.ExecutedBy))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<CreateDirectExecutionAuditResponseFileLinkOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<CreateDirectExecutionAuditResponseFileLinkOutput>.CreateFailure(ex);
        }
    }
}