using ServiceHubEnterprise.Web.Components;
using ServiceHubEnterprise.Dashboard;
using ServiceHubEnterprise.RestApplications;
using ServiceHubEnterprise.SoapApplications;
using ServiceHubEnterprise.FileManagement;
using ServiceHubEnterprise.TestSuite;
using ServiceHubEnterprise.MonitoringHealth;
using ServiceHubEnterprise.ADViewer;
using ServiceHubEnterprise.Settings;
using Microsoft.AspNetCore.Mvc.RazorPages;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddRazorPages(options =>
{
    // Discover _Host.cshtml from the Components folder
    options.RootDirectory = "/Components";
});

// Register Feature services
builder.Services
    .AddDashboardFeature()
    .AddRestApplicationsFeature()
    .AddSoapApplicationsFeature()
    .AddFileManagementFeature()
    .AddTestSuiteFeature()
    .AddMonitoringHealthFeature()
    .AddADViewerFeature()
    .AddSettingsFeature();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}
app.UseStaticFiles();

app.UseRouting();

app.UseAntiforgery();

app.MapRazorPages();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
