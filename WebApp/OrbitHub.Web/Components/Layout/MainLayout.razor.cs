using Microsoft.AspNetCore.Components;

namespace OrbitHub.Web.Components.Layout;

public partial class MainLayout
{
    [Parameter]
    public string Title { get; set; } = "Service Hub Enterprise";
}
