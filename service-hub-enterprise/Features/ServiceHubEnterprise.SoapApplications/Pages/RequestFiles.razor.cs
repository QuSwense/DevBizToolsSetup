using Microsoft.AspNetCore.Components.Forms;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class RequestFiles
{
    private record RequestFile(string FileName, string AppName, string ApiPath, string Verb, string Description, string Updated, string Created);
    private class UploadFileEntry
    {
        public string FileName { get; set; } = "";
        public string Content { get; set; } = "";
    }

    private List<GridColumn<RequestFile>> _columns = [];
    private HashSet<string> _expandedActionRows = [];

    private bool _showUploadModal = false;
    private string _uploadAppName = "";
    private string _uploadApiPath = "";
    private string _uploadDescription = "";
    private List<UploadFileEntry> _uploadFiles = [];
    private List<string> _validationErrors = [];

    private string[] _availableApps => _appStore.Apps.Select(a => a.Name).OrderBy(a => a).ToArray();
    private SoapApiEntry[] _availableOperations =>
        _appStore.Apps.FirstOrDefault(a => a.Name == _uploadAppName)?.Apis ?? [];

    private RequestFile[] _files = [];

    private static string GetVerbFromOperation(string operationName)
    {
        if (string.IsNullOrWhiteSpace(operationName))
            return "POST";
        var name = operationName.Trim();
        if (name.StartsWith("Get", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Find", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Search", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("List", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Check", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Validate", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Track", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Export", StringComparison.OrdinalIgnoreCase))
            return "GET";
        return "POST";
    }

    protected override void OnInitialized()
    {
        _columns =
        [
            new()
            {
                Title = "File Name",
                Sortable = true,
                Field = f => f.FileName,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "mono-text");
                    builder.AddContent(2, context.FileName);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Application",
                Sortable = true,
                Field = f => f.AppName,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.AppName);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Operation",
                Sortable = true,
                Field = f => f.ApiPath,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "cell-id");
                    builder.AddContent(2, context.ApiPath);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Updated",
                Sortable = true,
                Field = f => f.Updated,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.Updated);
                    builder.CloseElement();
                }
            }
        ];
    }

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        _files = await _mockDbLoader.LoadJsonAsync<RequestFile[]>("request-files.json");
    }

    private void AddUploadFileEntry()
    {
        _uploadFiles = [.._uploadFiles, new UploadFileEntry()];
    }

    private void RemoveUploadFileEntry(int index)
    {
        _uploadFiles = [.._uploadFiles.Where((_, i) => i != index)];
    }

    private async Task HandleLocalFileUpload(InputFileChangeEventArgs e)
    {
        foreach (var file in e.GetMultipleFiles())
        {
            if (file.Size > 10 * 1024 * 1024)
                continue;

            using var stream = file.OpenReadStream(maxAllowedSize: 10 * 1024 * 1024);
            using var reader = new StreamReader(stream);
            var content = await reader.ReadToEndAsync();
            _uploadFiles = [.._uploadFiles, new UploadFileEntry { FileName = file.Name, Content = content }];
        }
    }

    private void HandleUploadFiles()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_uploadAppName))
            _validationErrors.Add("Application is required.");
        if (string.IsNullOrWhiteSpace(_uploadApiPath))
            _validationErrors.Add("Operation is required.");

        var validFiles = _uploadFiles.Where(f => !string.IsNullOrWhiteSpace(f.FileName)).ToArray();
        if (validFiles.Length == 0)
            _validationErrors.Add("At least one file with a file name is required.");

        if (_validationErrors.Count > 0)
            return;

        var today = DateTime.Now.ToString("yyyy-MM-dd");
        var verb = GetVerbFromOperation(_uploadApiPath);

        var newFiles = validFiles.Select(f => new RequestFile(
            f.FileName.Trim(),
            _uploadAppName.Trim(),
            _uploadApiPath.Trim(),
            verb,
            _uploadDescription.Trim(),
            today,
            today
        )).ToArray();

        _files = [.._files, ..newFiles];

        // Reset form
        _uploadAppName = "";
        _uploadApiPath = "";
        _uploadDescription = "";
        _uploadFiles = [];
        _showUploadModal = false;
    }
}
