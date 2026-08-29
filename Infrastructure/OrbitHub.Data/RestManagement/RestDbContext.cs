using LinqToDB;
using LinqToDB.Data;

namespace OrbitHub.Data.RestManagement;

/// <summary>
/// linq2db data connection exposing the REST application request-file tables.
/// </summary>
public partial class RestDbContext : DataConnection
{
    public RestDbContext()
    {
    }

    public RestDbContext(string configuration)
        : base(configuration)
    {
    }

    public RestDbContext(DataOptions<RestDbContext> options)
        : base(options.Options)
    {
    }

    public ITable<RestRequestFileEntity> RestRequestFiles => this.GetTable<RestRequestFileEntity>();
}
