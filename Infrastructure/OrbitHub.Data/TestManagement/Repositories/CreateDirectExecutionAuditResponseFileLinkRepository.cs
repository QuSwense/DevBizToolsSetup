using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.TestManagement.Models;

namespace OrbitHub.Data.TestManagement.Repositories;

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