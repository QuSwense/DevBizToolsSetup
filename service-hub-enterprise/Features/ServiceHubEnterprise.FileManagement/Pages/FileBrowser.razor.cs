using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.FileManagement.Pages;

public partial class FileBrowser
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadBrowserAsync();
    }

    private async Task LoadBrowserAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate loading delay
            await Task.Delay(500);
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load file browser: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void DismissError()
    {
        _hasError = false;
        _errorMessage = null;
    }

    private void GoBack()
    {
        Nav.NavigateTo("/file/library");
    }
}