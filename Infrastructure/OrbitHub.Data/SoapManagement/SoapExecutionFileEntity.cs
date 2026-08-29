using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapExecutionFiles")]
public partial class SoapExecutionFileEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("GroupId", CanBeNull = false)]
    public string GroupId { get; set; } = null!;
    [Column("FileName", CanBeNull = false)]
    public string FileName { get; set; } = null!;
    [Column("AppName", CanBeNull = false)]
    public string AppName { get; set; } = null!;
    [Column("Operation", CanBeNull = false)]
    public string Operation { get; set; } = null!;
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("Stage")]
    public int Stage { get; set; }
    [Column("StagesCompleted")]
    public int StagesCompleted { get; set; }
    [Column("StagesTotal")]
    public int StagesTotal { get; set; }
    [Column("RequestContent")]
    public string? RequestContent { get; set; }
    [Column("ResponseContent")]
    public string? ResponseContent { get; set; }
    [Column("ResponseMimeType")]
    public string? ResponseMimeType { get; set; }

    #region Associations
    [Association(CanBeNull = false, ThisKey = nameof(GroupId), OtherKey = nameof(SoapExecutionGroupEntity.Id))]
    public SoapExecutionGroupEntity Group { get; set; } = null!;

    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapExecutionLogEntity.ExecutionFileId))]
    public IEnumerable<SoapExecutionLogEntity> Logs { get; set; } = null!;

    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapParsedFieldEntity.ExecutionFileId))]
    public IEnumerable<SoapParsedFieldEntity> ParsedFields { get; set; } = null!;

    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapExtractionResultEntity.ExecutionFileId))]
    public IEnumerable<SoapExtractionResultEntity> Extractions { get; set; } = null!;
    #endregion
}
