namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Combined output model containing both result sets returned by stored procedure [dbo].[usp_SaveServiceRequestFile].
/// </summary>
public class SaveServiceRequestFileResult
{
    public SaveServiceRequestFileOutput? File { get; set; }

    public List<SaveServiceRequestFileLinkOutput> Links { get; set; } = [];
}

