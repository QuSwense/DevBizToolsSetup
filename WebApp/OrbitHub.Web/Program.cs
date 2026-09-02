using OrbitHub.Dashboard;
using OrbitHub.RestApplications;
using OrbitHub.SoapApplications;
using OrbitHub.FileManagement;
using OrbitHub.TestSuite;
using OrbitHub.MonitoringHealth;
using OrbitHub.ADViewer;
using OrbitHub.Settings;
using OrbitHub.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddRazorPages(options =>
{
    // Discover _Host.cshtml from the Components folder
    options.RootDirectory = "/Components";
});

// ── Database (MSSQL, per-feature linq2db DbContexts) ──
var connectionString = ServiceHubDataConfig.GetConnectionString(builder.Configuration);
builder.Services.AddServiceHubData(connectionString);

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
