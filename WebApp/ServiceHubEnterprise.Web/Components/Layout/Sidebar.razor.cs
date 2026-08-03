using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Routing;

namespace ServiceHubEnterprise.Web.Components.Layout;

public partial class Sidebar : IDisposable
{
    private string currentPage = "/";
    private bool _collapsed;
    private HashSet<string> _expandedSections = new();

    private const string SoapSection = "soap";
    private const string RestSection = "rest";
    private const string FileSection = "file";
    private const string TestSection = "test";

    // Navigation is injected via @inject in Sidebar.razor — no [Inject] needed here.

    private bool IsExpanded(string section) =>
        _expandedSections.Contains(section) || currentPage.StartsWith("/" + section);

    private string GetMenuSectionClass(bool isActiveRoute, bool isExpanded)
    {
        var c = "menu-item";
        if (isActiveRoute) c += " active";
        if (isExpanded) c += " open";
        return c;
    }

    private string GetSubmenuClass(bool isExpanded) =>
        isExpanded ? "submenu submenu-open" : "submenu";

    private void ToggleSection(string section)
    {
        if (!_expandedSections.Remove(section))
            _expandedSections.Add(section);
    }

    private void ToggleSoap() => ToggleSection(SoapSection);
    private void ToggleRest() => ToggleSection(RestSection);
    private void ToggleFile() => ToggleSection(FileSection);
    private void ToggleTest() => ToggleSection(TestSection);

    private void ToggleCollapse()
    {
        _collapsed = !_collapsed;
    }

    private void NavigateTo(string url)
    {
        Navigation.NavigateTo(url);
    }

    protected override void OnInitialized()
    {
        UpdateCurrentPage();
        Navigation.LocationChanged += OnLocationChanged;
    }

    private void OnLocationChanged(object? sender, LocationChangedEventArgs e)
    {
        UpdateCurrentPage();
        StateHasChanged();
    }

    private void UpdateCurrentPage()
    {
        var path = Navigation.ToBaseRelativePath(Navigation.Uri);
        currentPage = string.IsNullOrEmpty(path) ? "/" : "/" + path;
    }

    public void Dispose()
    {
        Navigation.LocationChanged -= OnLocationChanged;
    }
}
