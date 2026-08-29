using Microsoft.AspNetCore.Components;
using OrbitHub.Grid.Components;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Components;

/// <summary>
/// Code-behind for the Templates overview section card.
/// Shows template totals, extends-chain stats, and a drill-down grid.
/// </summary>
public partial class TemplatesOverview
{
    /// <summary>
    /// Gets or sets the request-file templates to display.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlTemplate> Templates { get; set; } = [];

    /// <summary>
    /// Gets or sets whether the card is collapsed to its summary view.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the card's collapse state is toggled.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    private List<GridColumn<WsdlTemplate>> _columns = [];

    private int ExtendingCount => Templates.Count(t => !string.IsNullOrEmpty(t.ExtendsTemplateId));
    private int TotalVariables => Templates.Sum(t => t.Variables.Length);
    private int TotalUsage => Templates.Sum(t => t.Variables.Length);

    /// <inheritdoc />
    protected override void OnInitialized()
    {
        _columns =
        [
            new() { Title = "Template", Sortable = true, Field = t => t.Name },
            new() { Title = "Description", Sortable = true, Field = t => t.Description, CssClass = "cell-truncated" },
            new()
            {
                Title = "Extends", Sortable = true, Field = t => t.ExtendsTemplateName ?? "—", Width = "180px",
                Template = ctx => builder =>
                {
                    if (string.IsNullOrEmpty(ctx.ExtendsTemplateName))
                    {
                        builder.OpenElement(0, "span");
                        builder.AddAttribute(1, "class", "text-sh-faint");
                        builder.AddContent(2, "—");
                        builder.CloseElement();
                        return;
                    }

                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "sb-badge sb-none");
                    builder.AddContent(2, ctx.ExtendsTemplateName);
                    builder.CloseElement();
                }
            },
            new() { Title = "Variables", Sortable = true, Field = t => t.Variables.Length, Width = "100px" },
            new() { Title = "Usage", Sortable = true, Field = t => t.Variables.Length, Width = "90px" },
            new() { Title = "Updated", Sortable = true, Field = t => t.UpdatedAt ?? "—", Width = "120px" }
        ];
    }
}
