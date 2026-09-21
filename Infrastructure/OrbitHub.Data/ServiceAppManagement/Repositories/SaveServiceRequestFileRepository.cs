using System.Data;
using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.ServiceAppManagement.Models;

namespace OrbitHub.Data.ServiceAppManagement.Repositories;

public class SaveServiceRequestFileRepository(ServiceAppDbContext ctx)
{
    private readonly ServiceAppDbContext _ctx = ctx;

    public async Task<RepositoryResult<SaveServiceRequestFileOutput>> ExecuteAsync(
        SaveServiceRequestFileInput input,
        CancellationToken ct = default)
    {
        try
        {
            var tvpTable = new DataTable();
            tvpTable.Columns.Add("ElementName", typeof(string));
            tvpTable.Columns.Add("XmlPath", typeof(string));
            tvpTable.Columns.Add("BinaryEmbeddingsStoreId", typeof(int));
            tvpTable.Columns.Add("Name", typeof(string));
            tvpTable.Columns.Add("AdditionalDetails", typeof(string));

            if (input.EmbeddingLinks != null)
            {
                foreach (var link in input.EmbeddingLinks)
                {
                    tvpTable.Rows.Add(
                        link.ElementName,
                        link.XmlPath,
                        link.BinaryEmbeddingsStoreId,
                        link.Name,
                        (object?)link.AdditionalDetails ?? DBNull.Value);
                }
            }

            var result = (await _ctx.QueryProcAsync<SaveServiceRequestFileOutput>(
                "[dbo].[usp_SaveServiceRequestFile]",
                new DataParameter("@ServiceOperationId", input.ServiceOperationId),
                new DataParameter("@FileFormat", input.FileFormat),
                new DataParameter("@Name", input.Name),
                new DataParameter("@CompressedData", input.CompressedData),
                new DataParameter("@UncompressedSizeBytes", input.UncompressedSizeBytes),
                new DataParameter("@CompressionAlgorithmType", input.CompressionAlgorithmType),
                new DataParameter("@IsActive", input.IsActive),
                new DataParameter("@EmbeddingLinks", tvpTable, DataType.Structured),
                new DataParameter("@UserId", input.UserId)
            )).ToList();

            return RepositoryResult<SaveServiceRequestFileOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex)
        {
            return RepositoryResult<SaveServiceRequestFileOutput>.Fail(ex.Message);
        }
    }
}
