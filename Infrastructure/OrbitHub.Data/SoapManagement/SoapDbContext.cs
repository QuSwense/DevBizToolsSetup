using LinqToDB;
using LinqToDB.Data;

namespace OrbitHub.Data.SoapManagement;

/// <summary>
/// linq2db data connection exposing the SOAP application/execution/test-case tables.
/// </summary>
public partial class SoapDbContext : DataConnection
{
    public SoapDbContext()
    {
    }

    public SoapDbContext(string configuration)
        : base(configuration)
    {
    }

    public SoapDbContext(DataOptions<SoapDbContext> options)
        : base(options.Options)
    {
    }

    public ITable<SoapAppEntity> SoapApps => this.GetTable<SoapAppEntity>();
    public ITable<SoapApiEntity> SoapApis => this.GetTable<SoapApiEntity>();
    public ITable<SoapExecutionGroupEntity> SoapExecutionGroups => this.GetTable<SoapExecutionGroupEntity>();
    public ITable<SoapExecutionFileEntity> SoapExecutionFiles => this.GetTable<SoapExecutionFileEntity>();
    public ITable<SoapExecutionLogEntity> SoapExecutionLogs => this.GetTable<SoapExecutionLogEntity>();
    public ITable<SoapParsedFieldEntity> SoapParsedFields => this.GetTable<SoapParsedFieldEntity>();
    public ITable<SoapExtractionResultEntity> SoapExtractionResults => this.GetTable<SoapExtractionResultEntity>();
    public ITable<SoapTestCaseEntity> SoapTestCases => this.GetTable<SoapTestCaseEntity>();
    public ITable<SoapExtractorEntity> SoapExtractors => this.GetTable<SoapExtractorEntity>();
    public ITable<SoapRequestFileEntity> SoapRequestFiles => this.GetTable<SoapRequestFileEntity>();
}
