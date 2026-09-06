using System.IO.Compression;
using System.Text;
using LinqToDB;
using LinqToDB.Async;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.ServiceAppManagement;

namespace OrbitHub.FileManagement.Services;

public sealed class FileStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private readonly List<ManagedRequestFile> _versions = [];

    public async Task<ManagedRequestFile?> GetFileAsync(string applicationName, string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ServiceAppDbContext>();

        var file = await (
            from requestFile in db.ServiceRequestFiles
            join operation in db.ServiceOperations on requestFile.ServiceOperationId equals operation.Id
            join application in db.ServiceApplications on operation.ServiceApplicationId equals application.Id
            where requestFile.Name == fileName && application.Name == applicationName
            select new { requestFile, operation, application })
            .FirstOrDefaultAsync();

        return file is null ? null : ToManagedFile(file.requestFile, file.operation, file.application);
    }

    public Task<int> GetVersionCountAsync(int fileId) =>
        Task.FromResult(_versions.Count(version => version.Id == fileId));

    public Task<ManagedRequestFile?> GetPreviousVersionAsync(int fileId) =>
        Task.FromResult(_versions.LastOrDefault(version => version.Id == fileId));

    public async Task SaveAsync(ManagedRequestFile file, string fileName, string description, bool isActive,
        string content, string updatedBy)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ServiceAppDbContext>();
        var entity = await db.ServiceRequestFiles.FirstOrDefaultAsync(requestFile => requestFile.Id == file.Id)
            ?? throw new InvalidOperationException("The request file no longer exists.");

        _versions.Add(file);

        entity.Name = fileName;
        entity.IsActive = isActive;
        entity.LastUpdatedBy = updatedBy;
        entity.LastUpdatedAt = DateTime.UtcNow;
        entity.CompressedData = Encoding.UTF8.GetBytes(content);
        entity.UncompressedSizeBytes = entity.CompressedData.Length;
        entity.CompressionAlgorithmType = "None";
        await db.UpdateAsync(entity);
    }

    private static ManagedRequestFile ToManagedFile(ServiceRequestFile requestFile, ServiceOperation operation,
        ServiceApplication application) => new()
        {
            Id = requestFile.Id,
            FileName = requestFile.Name,
            ApplicationName = application.Name,
            ServiceType = application.ServiceType,
            Operation = operation.OperationName,
            Verb = operation.HttpMethod ?? (application.ServiceType == "SOAP" ? "POST" : string.Empty),
            Description = operation.Description ?? string.Empty,
            IsActive = requestFile.IsActive,
            CreatedBy = requestFile.CreatedBy,
            CreatedAt = requestFile.CreatedAt,
            LastUpdatedBy = requestFile.LastUpdatedBy,
            LastUpdatedAt = requestFile.LastUpdatedAt,
            Content = ReadContent(requestFile)
        };

    private static string ReadContent(ServiceRequestFile requestFile)
    {
        if (!string.Equals(requestFile.CompressionAlgorithmType, "GZip", StringComparison.OrdinalIgnoreCase))
        {
            return Encoding.UTF8.GetString(requestFile.CompressedData);
        }

        using var input = new MemoryStream(requestFile.CompressedData);
        using var gzip = new GZipStream(input, CompressionMode.Decompress);
        using var reader = new StreamReader(gzip, Encoding.UTF8);
        return reader.ReadToEnd();
    }
}

public sealed class ManagedRequestFile
{
    public int Id { get; init; }
    public string FileName { get; init; } = string.Empty;
    public string ApplicationName { get; init; } = string.Empty;
    public string ServiceType { get; init; } = string.Empty;
    public string Operation { get; init; } = string.Empty;
    public string Verb { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public string CreatedBy { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public string? LastUpdatedBy { get; init; }
    public DateTime? LastUpdatedAt { get; init; }
    public string Content { get; init; } = string.Empty;
}