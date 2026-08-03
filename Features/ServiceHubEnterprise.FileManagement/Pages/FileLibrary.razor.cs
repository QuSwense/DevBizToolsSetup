using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.FileManagement.Core.Enums;
using ServiceHubEnterprise.FileManagement.Models;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.FileManagement.Pages;

public partial class FileLibrary
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    // ── Skeleton loading renderer ──
    private RenderFragment RenderSkeletonRows => builder =>
    {
        for (var i = 0; i < 5; i++)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "skeleton-row");
            BuildSkeletonCell(builder, "skeleton-check");
            BuildSkeletonCell(builder, "skeleton-name", "w-60");
            BuildSkeletonCell(builder, "skeleton-app", "w-50");
            BuildSkeletonCell(builder, "skeleton-type", "w-40");
            BuildSkeletonCell(builder, "skeleton-size", "w-30");
            BuildSkeletonCell(builder, "skeleton-linked", "w-50");
            BuildSkeletonCell(builder, "skeleton-actions", "w-40");
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

    private List<GridColumn<FileItem>> _columns = [];

    // ── Loading / Error / Empty State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;
    private FileItem[] _allFiles = [];

    // ── Grid state ──
    private string _searchText = "";
    private int _currentPage = 1;
    private string _sortColumn = "";
    private bool _sortAscending = true;
    private HashSet<string> _selectedIds = [];
    private ServiceHubGrid<FileItem>? _grid;

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        _columns =
        [
            new()
            {
                Title = "File Name",
                Sortable = true,
                Field = f => f.FileName,
                Template = context => builder =>
                {
                    var file = context;
                    var typeColor = file.Type switch
                    {
                        FileType.Json => "var(--sh-success)",
                        FileType.Xml => "var(--sh-warning)",
                        FileType.Wsdl => "var(--sh-accent)",
                        FileType.Pdf => "var(--sh-error)",
                        _ => "var(--sh-text-faint)"
                    };
                    var icon = file.Type switch
                    {
                        FileType.Json => "bi-filetype-json",
                        FileType.Xml => "bi-filetype-xml",
                        FileType.Wsdl => "bi-filetype-xml",
                        FileType.Pdf => "bi-filetype-pdf",
                        _ => "bi-file-earmark-code"
                    };
                    builder.OpenElement(0, "div");
                    builder.AddAttribute(1, "class", "name-stack");
                    builder.OpenElement(2, "i");
                    builder.AddAttribute(3, "class", $"bi {icon} file-icon");
                    builder.AddAttribute(4, "style", $"color:{typeColor}");
                    builder.CloseElement();
                    builder.OpenElement(5, "span");
                    builder.AddAttribute(6, "class", "file-name");
                    builder.AddContent(7, file.FileName);
                    builder.CloseElement();
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
                Title = "Type",
                Sortable = true,
                Field = f => f.Type.ToString(),
                Template = context => builder =>
                {
                    var badgeClass = context.Type switch
                    {
                        FileType.Json => "type-badge-json",
                        FileType.Xml => "type-badge-xml",
                        FileType.Wsdl => "type-badge-wsdl",
                        FileType.Pdf => "type-badge-pdf",
                        _ => "type-badge-other"
                    };
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"type-badge {badgeClass} text-uppercase");
                    builder.AddContent(2, context.Type.ToString());
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Size",
                Sortable = true,
                Field = f => f.Size,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.Size);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Linked To",
                Sortable = true,
                Field = f => f.LinkedTo,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "cell-truncated");
                    builder.AddContent(2, context.LinkedTo);
                    builder.CloseElement();
                }
            }
        ];

        await LoadFilesAsync();
    }

    private async Task LoadFilesAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible
            await Task.Delay(800);

            // Hardcoded data matching the original inline data — no logic changes
            _allFiles =
            [
                new()
                {
                    Id = "1",
                    FileName = "payment_create_001.json",
                    AppName = "PaymentService",
                    Type = FileType.Json,
                    Size = "2.4 KB",
                    LinkedTo = "PaymentService /payments POST"
                },
                new()
                {
                    Id = "2",
                    FileName = "user_list_filter.xml",
                    AppName = "UserManagement",
                    Type = FileType.Xml,
                    Size = "1.8 KB",
                    LinkedTo = "UserManagement /users GET"
                },
                new()
                {
                    Id = "3",
                    FileName = "invoice_create.xml",
                    AppName = "LegacyBilling",
                    Type = FileType.Xml,
                    Size = "3.1 KB",
                    LinkedTo = "LegacyBilling CreateInvoice POST"
                },
                new()
                {
                    Id = "4",
                    FileName = "stock_update_003.json",
                    AppName = "InventoryAPI",
                    Type = FileType.Json,
                    Size = "1.2 KB",
                    LinkedTo = "InventoryAPI /stock PUT"
                }
            ];
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load files: {ex.Message}";
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

    private FileItem[] FilteredFiles
    {
        get
        {
            var query = _allFiles.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.ToLower();
                query = query.Where(f =>
                    f.FileName.ToLower().Contains(q) ||
                    f.AppName.ToLower().Contains(q) ||
                    f.LinkedTo.ToLower().Contains(q) ||
                    f.Type.ToString().ToLowerInvariant().Contains(q));
            }

            if (!string.IsNullOrWhiteSpace(_sortColumn))
            {
                query = _sortColumn switch
                {
                    "FileName" => _sortAscending ? query.OrderBy(f => f.FileName) : query.OrderByDescending(f => f.FileName),
                    "AppName" => _sortAscending ? query.OrderBy(f => f.AppName) : query.OrderByDescending(f => f.AppName),
                    "Type" => _sortAscending ? query.OrderBy(f => f.Type) : query.OrderByDescending(f => f.Type),
                    "Size" => _sortAscending ? query.OrderBy(f => f.Size) : query.OrderByDescending(f => f.Size),
                    "LinkedTo" => _sortAscending ? query.OrderBy(f => f.LinkedTo) : query.OrderByDescending(f => f.LinkedTo),
                    _ => query
                };
            }

            return query.ToArray();
        }
    }

    private void HandleViewFile(FileItem file)
    {
        Nav.NavigateTo($"/file/viewer?app={file.AppName}&file={file.FileName}");
    }

    private void HandleDownloadFile(FileItem file)
    {
        // Placeholder for download — no logic change
    }

    private void HandleDeleteFile(FileItem file)
    {
        // Placeholder for delete — no logic change
    }
}