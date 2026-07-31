using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

/// <summary>
/// Code-behind for the SOAP overview landing page.
/// Loads all datasets from the feature stores once and feeds the 5 section cards.
/// </summary>
public partial class SoapOverview
{
    [Inject] private SoapAppStore AppStore { get; set; } = default!;
    [Inject] private WsdlSyncStore WsdlStore { get; set; } = default!;
    [Inject] private RequestExecutionStore ExecutionStore { get; set; } = default!;
    [Inject] private MockDbLoader MockDb { get; set; } = default!;

    private bool _isLoading = true;

    private SoapApp[] Apps = [];
    private WsdlSyncRecord[] Records = [];
    private WsdlVersionEntry[] Versions = [];
    private WsdlSyncHistoryPoint[] SyncHistory = [];
    private WsdlTemplate[] Templates = [];
    private SoapExecution[] Executions = [];
    private SoapRequestFile[] Files = [];

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

            var filesTask = MockDb.LoadJsonAsync<SoapRequestFile[]>("request-files.json");
            await Task.WhenAll(filesTask);
            Files = filesTask.Result ?? [];
        }
        finally
        {
            _isLoading = false;
        }
    }
}
