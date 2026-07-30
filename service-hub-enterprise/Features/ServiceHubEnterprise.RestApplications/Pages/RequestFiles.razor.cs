using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;

namespace ServiceHubEnterprise.RestApplications.Pages;

public partial class RequestFiles
{
    // ── Data Model ──

    private record RequestFileRecord(
        string FileName,
        string AppName,
        string ApiPath,
        string Verb,
        string Description,
        string Type,
        string Created
    );

    // ── Skeleton loading renderer ──

    private RenderFragment RenderSkeletonRows => builder =>
    {
        for (var i = 0; i < 5; i++)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "skeleton-row");
            BuildSkeletonCell(builder, "skeleton-check");
            BuildSkeletonCell(builder, "skeleton-filename", "w-70");
            BuildSkeletonCell(builder, "skeleton-app", "w-50");
            BuildSkeletonCell(builder, "skeleton-apipath", "w-60");
            BuildSkeletonCell(builder, "skeleton-verb", "w-30");
            BuildSkeletonCell(builder, "skeleton-description", "w-70");
            BuildSkeletonCell(builder, "skeleton-type", "w-30");
            BuildSkeletonCell(builder, "skeleton-created", "w-50");
            builder.CloseElement();
        }
    };

    private static void BuildSkeletonCell(RenderTreeBuilder builder, string cellClass, string? barClass = null)
    {
        builder.OpenElement(0, "div");
        builder.AddAttribute(1, "class", $"skeleton-cell {cellClass}");
        if (barClass is not null)
        {
            builder.OpenElement(2, "div");
            builder.AddAttribute(3, "class", $"skeleton-bar {barClass}");
            builder.CloseElement();
        }
        builder.CloseElement();
    }

    // ── Loading / Error State ──

    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;
    private RequestFileRecord[] _allFiles = [];

    // ── Lifecycle ──

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadFilesAsync();
    }

    // ── Data Loading ──

    private async Task LoadFilesAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible
            await Task.Delay(1500);

            _allFiles =
            [
                new("payment_create_001.json", "PaymentService", "/payments", "POST",
                    "Valid payment with card 4111", "json", "2024-04-01"),
                new("user_list_filter.xml", "UserManagement", "/users", "GET",
                    "List active users filtered by role admin", "xml", "2024-04-02"),
                new("stock_update_003.json", "InventoryAPI", "/stock", "PUT",
                    "Update stock for SKU-889", "json", "2024-04-03")
            ];
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load request files: {ex.Message}";
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
}
