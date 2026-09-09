using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class CreateServiceOperationWithSchemaRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult<GetServiceOperationByIdOutput>> ExecuteAsync(
        CreateServiceOperationWithSchemaInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<GetServiceOperationByIdOutput>(
                "usp_CreateServiceOperationWithSchema",
                new DataParameter("@ServiceApplicationId", input.ServiceApplicationId),
                new DataParameter("@OperationName", input.OperationName),
                new DataParameter("@EndpointOrAction", input.EndpointOrAction),
                new DataParameter("@HttpMethod", input.HttpMethod),
                new DataParameter("@Description", input.Description),
                new DataParameter("@InputRootElementName", input.InputRootElementName),
                new DataParameter("@OutputRootElementName", input.OutputRootElementName),
                new DataParameter("@TargetNamespace", input.TargetNamespace),
                new DataParameter("@CompressedSchemaContent", input.CompressedSchemaContent),
                new DataParameter("@UserId", input.UserId))
            .ConfigureAwait(false)).FirstOrDefault()!;

            return RepositoryResult<GetServiceOperationByIdOutput>.CreateSuccess(result);
        }
        catch (Exception ex)
        {
            return RepositoryResult<GetServiceOperationByIdOutput>.CreateFailure(ex);
        }
    }
}