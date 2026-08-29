using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using OrbitHub.SoapApplications.Models;
using OrbitHub.SoapApplications.Services;

namespace OrbitHub.SoapApplications.Pages;

/// <summary>
/// Code-behind for the SOAP overview landing page.
/// Loads all datasets from the feature stores once and feeds the 5 section cards.
/// </summary>
public partial class SoapOverview
{
    [Inject] private SoapAppStore AppStore { get; set; } = default!;
    [Inject] private WsdlSyncStore WsdlStore { get; set; } = default!;
    [Inject] private RequestExecutionStore ExecutionStore { get; set; } = default!;
    [Inject] private IJSRuntime Js { get; set; } = default!;

    private bool _isLoading = true;

    private SoapApp[] Apps = [];
    private WsdlSyncRecord[] Records = [];
    private WsdlVersionEntry[] Versions = [];
    private WsdlSyncHistoryPoint[] SyncHistory = [];
    private WsdlTemplate[] Templates = [];
    private SoapExecution[] Executions = [];
    private SoapRequestFile[] Files = [];

    // Per-card expand/collapse state, persisted to localStorage via JS interop.
    // Cards default to collapsed (compact summary) so the page stays short.
    private readonly Dictionary<string, bool> _cardCollapsed = new();
    private IJSObjectReference? _collapseModule;

    /// <inheritdoc />
    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        try
        {
            // Singleton stores are populated at construction; request files load async.
            Apps = AppStore.Apps;
            Records = WsdlStore.Records.ToArray();
            Versions = WsdlStore.Versions.ToArray();
            SyncHistory = WsdlStore.SyncHistory.ToArray();
            Templates = WsdlStore.Templates.ToArray();
            Executions = ExecutionStore.SoapExecutions;

            // Request files are not yet backed by a database table — previously loaded
            // from mock JSON. TODO: load from MSSQL (SoapRequestFiles) once the schema exists.
            Files = [];
        }
        finally
        {
            _isLoading = false;
        }
    }

    /// <inheritdoc />
    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (!firstRender)
        {
            return;
        }

        // Hydrate the persisted per-card collapse state once the client circuit is live.
        try
        {
            _collapseModule = await Js.InvokeAsync<IJSObjectReference>(
                "import", "./_content/OrbitHub.Ui/js/collapse.js");
            var saved = await _collapseModule.InvokeAsync<Dictionary<string, bool>>("getAll");
            if (saved is not null)
            {
                foreach (var (key, collapsed) in saved)
                {
                    _cardCollapsed[key] = collapsed;
                }
            }
        }
        catch
        {
            // Interop unavailable (e.g. prerender) — fall back to default (collapsed) state.
        }

        StateHasChanged();
    }

    private bool IsCollapsed(string key) =>
        _cardCollapsed.TryGetValue(key, out var collapsed) ? collapsed : true;

    private async Task ToggleCard(string key, bool collapsed)
    {
        _cardCollapsed[key] = collapsed;
        if (_collapseModule is not null)
        {
            await _collapseModule.InvokeVoidAsync("set", key, collapsed);
        }
    }

    private Task OnApplicationsToggle(bool collapsed) => ToggleCard(CardKey.Applications, collapsed);
    private Task OnRequestFilesToggle(bool collapsed) => ToggleCard(CardKey.RequestFiles, collapsed);
    private Task OnExecutionsToggle(bool collapsed) => ToggleCard(CardKey.Executions, collapsed);
    private Task OnWsdlSyncToggle(bool collapsed) => ToggleCard(CardKey.WsdlSync, collapsed);
    private Task OnTemplatesToggle(bool collapsed) => ToggleCard(CardKey.Templates, collapsed);

    /// <inheritdoc />
    public async ValueTask DisposeAsync()
    {
        if (_collapseModule is not null)
        {
            await _collapseModule.DisposeAsync();
        }
    }

    private static class CardKey
    {
        public const string Applications = "soap-apps";
        public const string RequestFiles = "soap-request-files";
        public const string Executions = "soap-executions";
        public const string WsdlSync = "soap-wsdl-sync";
        public const string Templates = "soap-templates";
    }
}
