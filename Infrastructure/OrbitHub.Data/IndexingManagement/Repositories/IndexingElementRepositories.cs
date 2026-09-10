using LinqToDB.Data;
using OrbitHub.Data.Common;

namespace OrbitHub.Data.IndexingManagement.Repositories;

public class InsertOrGetXmlFileElementRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetXmlFileElementOutput>> ExecuteAsync(InsertOrGetXmlFileElementInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetXmlFileElementOutput>("[dbo].[usp_InsertOrGetXmlFileElement]", new DataParameter("@ElementName", input.ElementName), new DataParameter("@XmlPath", input.XmlPath), new DataParameter("@ValueType", input.ValueType), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetXmlFileElementOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetXmlFileElementOutput>.Fail(ex.Message); }
    }
}

public class InsertOrGetJsonFileElementRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetJsonFileElementOutput>> ExecuteAsync(InsertOrGetJsonFileElementInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetJsonFileElementOutput>("[dbo].[usp_InsertOrGetJsonFileElement]", new DataParameter("@ElementName", input.ElementName), new DataParameter("@JsonPath", input.JsonPath), new DataParameter("@ValueType", input.ValueType), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetJsonFileElementOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetJsonFileElementOutput>.Fail(ex.Message); }
    }
}

public class InsertOrGetPdfFileElementRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetPdfFileElementOutput>> ExecuteAsync(InsertOrGetPdfFileElementInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetPdfFileElementOutput>("[dbo].[usp_InsertOrGetPdfFileElement]", new DataParameter("@ElementName", input.ElementName), new DataParameter("@ElementType", input.ElementType), new DataParameter("@PageNumber", input.PageNumber), new DataParameter("@BoundingRectangle", input.BoundingRectangle), new DataParameter("@ValueType", input.ValueType), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetPdfFileElementOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetPdfFileElementOutput>.Fail(ex.Message); }
    }
}

public class InsertOrGetXmlFileElementSearchRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetXmlFileElementSearchOutput>> ExecuteAsync(InsertOrGetXmlFileElementSearchInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetXmlFileElementSearchOutput>("[dbo].[usp_InsertOrGetXmlFileElementSearch]", new DataParameter("@IndexingXmlFileElementId", input.IndexingXmlFileElementId), new DataParameter("@ElementValue", input.ElementValue), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetXmlFileElementSearchOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetXmlFileElementSearchOutput>.Fail(ex.Message); }
    }
}

public class InsertOrGetJsonFileElementSearchRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetJsonFileElementSearchOutput>> ExecuteAsync(InsertOrGetJsonFileElementSearchInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetJsonFileElementSearchOutput>("[dbo].[usp_InsertOrGetJsonFileElementSearch]", new DataParameter("@IndexingJsonFileElementId", input.IndexingJsonFileElementId), new DataParameter("@ElementValue", input.ElementValue), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetJsonFileElementSearchOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetJsonFileElementSearchOutput>.Fail(ex.Message); }
    }
}

public class InsertOrGetPdfFileElementSearchRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertOrGetPdfFileElementSearchOutput>> ExecuteAsync(InsertOrGetPdfFileElementSearchInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertOrGetPdfFileElementSearchOutput>("[dbo].[usp_InsertOrGetPdfFileElementSearch]", new DataParameter("@IndexingPdfFileElementId", input.IndexingPdfFileElementId), new DataParameter("@ElementValue", input.ElementValue), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertOrGetPdfFileElementSearchOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertOrGetPdfFileElementSearchOutput>.Fail(ex.Message); }
    }
}

public class InsertXmlFileElementMappingRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertXmlFileElementMappingOutput>> ExecuteAsync(InsertXmlFileElementMappingInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertXmlFileElementMappingOutput>("[dbo].[usp_InsertXmlFileElementMapping]", new DataParameter("@IndexingXmlFileElementSearchId", input.IndexingXmlFileElementSearchId), new DataParameter("@RequestFileId", input.RequestFileId), new DataParameter("@ResponseFileId", input.ResponseFileId), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertXmlFileElementMappingOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertXmlFileElementMappingOutput>.Fail(ex.Message); }
    }
}

public class InsertJsonFileElementMappingRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertJsonFileElementMappingOutput>> ExecuteAsync(InsertJsonFileElementMappingInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertJsonFileElementMappingOutput>("[dbo].[usp_InsertJsonFileElementMapping]", new DataParameter("@IndexingJsonFileElementSearchId", input.IndexingJsonFileElementSearchId), new DataParameter("@RequestFileId", input.RequestFileId), new DataParameter("@ResponseFileId", input.ResponseFileId), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertJsonFileElementMappingOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertJsonFileElementMappingOutput>.Fail(ex.Message); }
    }
}

public class InsertPdfFileElementMappingRepository(IndexingDbContext ctx)
{
    public async Task<RepositoryResult<InsertPdfFileElementMappingOutput>> ExecuteAsync(InsertPdfFileElementMappingInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await ctx.QueryProcAsync<InsertPdfFileElementMappingOutput>("[dbo].[usp_InsertPdfFileElementMapping]", new DataParameter("@IndexingPdfFileElementSearchId", input.IndexingPdfFileElementSearchId), new DataParameter("@BinaryEmbeddingsStoreId", input.BinaryEmbeddingsStoreId), new DataParameter("@UserId", input.UserId))).ToList();
            return RepositoryResult<InsertPdfFileElementMappingOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex) { return RepositoryResult<InsertPdfFileElementMappingOutput>.Fail(ex.Message); }
    }
}