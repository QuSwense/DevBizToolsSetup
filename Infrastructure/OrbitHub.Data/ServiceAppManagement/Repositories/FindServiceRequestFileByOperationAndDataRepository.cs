using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.ServiceAppManagement.Models;

namespace OrbitHub.Data.ServiceAppManagement.Repositories;

public class FindServiceRequestFileByOperationAndDataRepository(ServiceAppDbContext ctx)
{
    private readonly ServiceAppDbContext _ctx = ctx;

    public async Task<RepositoryResult<FindServiceRequestFileByOperationAndDataOutput>> ExecuteAsync(
        FindServiceRequestFileByOperationAndDataInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await _ctx.QueryProcAsync<FindServiceRequestFileByOperationAndDataOutput>(
                "[dbo].[usp_FindServiceRequestFileByOperationAndData]",
                new DataParameter("@ServiceOperationId", input.ServiceOperationId),
                new DataParameter("@Name", input.Name),
                new DataParameter("@CompressedData", input.CompressedData)
            )).ToList();

            return RepositoryResult<FindServiceRequestFileByOperationAndDataOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex)
        {
            return RepositoryResult<FindServiceRequestFileByOperationAndDataOutput>.Fail(ex.Message);
        }
    }
}