using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class Templates
{
    private record Template(string Name, string Type, string Updated, string Created, int Usage);

    private List<GridColumn<Template>> _columns = [];
    private HashSet<string> _expandedActionRows = [];

    private Template[] _templateItems = [];

    protected override void OnInitialized()
    {
        _columns =
        [
            new()
            {
                Title = "Template Name",
                Sortable = true,
                Field = t => t.Name,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "mono-text");
                    builder.AddContent(2, context.Name);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Updated",
                Sortable = true,
                Field = t => t.Updated,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.Updated);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Usage",
                Sortable = true,
                Field = t => t.Usage,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.Usage);
                    builder.AddContent(3, " uses");
                    builder.CloseElement();
                }
            }
        ];
    }

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        _templateItems = await _mockDbLoader.LoadJsonAsync<Template[]>("templates-page.json");
    }
}
