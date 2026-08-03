using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Web.Components.Layout;

public partial class MainLayout
{
    [Parameter]
    public string Title { get; set; } = "Service Hub Enterprise";
}
