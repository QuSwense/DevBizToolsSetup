using LinqToDB;
using LinqToDB.Data;

namespace OrbitHub.Data.WsdlManagement;

/// <summary>
/// linq2db data connection exposing the WSDL sync/version/template tables.
/// </summary>
public partial class WsdlDbContext : DataConnection
{
    public WsdlDbContext()
    {
    }

    public WsdlDbContext(string configuration)
        : base(configuration)
    {
    }

    public WsdlDbContext(DataOptions<WsdlDbContext> options)
        : base(options.Options)
    {
    }

    public ITable<WsdlRecordEntity> WsdlRecords => this.GetTable<WsdlRecordEntity>();
    public ITable<WsdlVersionEntity> WsdlVersions => this.GetTable<WsdlVersionEntity>();
    public ITable<WsdlTemplateEntity> WsdlTemplates => this.GetTable<WsdlTemplateEntity>();
    public ITable<WsdlSyncHistoryEntity> WsdlSyncHistory => this.GetTable<WsdlSyncHistoryEntity>();
}
