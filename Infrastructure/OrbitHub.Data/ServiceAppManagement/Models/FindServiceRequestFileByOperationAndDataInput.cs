namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Input model for stored procedure [dbo].[usp_FindServiceRequestFileByOperationAndData].
/// </summary>
public class FindServiceRequestFileByOperationAndDataInput
{
    public int ServiceOperationId { get; set; }

    public string? Name { get; set; }

    public byte[]? CompressedData { get; set; }
}