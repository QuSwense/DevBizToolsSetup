using LinqToDB;
using LinqToDB.Data;

namespace OrbitHub.Data.FileVersionManagement;

/// <summary>
/// linq2db data connection exposing saved-version snapshots for SOAP/REST request files.
/// </summary>
public partial class FileManagementDbContext : DataConnection
{
    public FileManagementDbContext()
    {
    }

    public FileManagementDbContext(string configuration)
        : base(configuration)
    {
    }

    public FileManagementDbContext(DataOptions<FileManagementDbContext> options)
        : base(options.Options)
    {
    }

    public ITable<FileVersionEntity> FileVersions => this.GetTable<FileVersionEntity>();
}
