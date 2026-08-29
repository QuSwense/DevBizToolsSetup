using System.Linq.Expressions;
using Microsoft.AspNetCore.Components;

namespace OrbitHub.Grid.Components;

/// <summary>
/// Defines a single column for the <see cref="ServiceHubGrid{TItem}"/> component.
/// Create instances in your <c>@code</c> block and pass as <c>Columns</c> parameter.
/// Example:
/// <code>
/// var cols = new List&lt;GridColumn&lt;SoapApp&gt;&gt;
/// {
///     new() { Title = "Name", Field = a => a.Name, Sortable = true },
///     new() { Title = "Status", Field = a => a.Status, Template = ctx => builder =&gt; { ... } }
/// };
/// </code>
/// </summary>
/// <typeparam name="TItem">The type of data item displayed in the grid.</typeparam>
public class GridColumn<TItem>
{
    /// <summary>
    /// Column header text displayed in the <c>&lt;thead&gt;</c>.
    /// </summary>
    public string? Title { get; set; }

    /// <summary>
    /// Optional expression pointing to the property used for display / sorting.
    /// Example: <c>app => app.Name</c>
    /// </summary>
    public Expression<Func<TItem, object?>>? Field { get; set; }

    /// <summary>
    /// Width CSS value (e.g. "120px", "15%"). If null, column auto-sizes.
    /// </summary>
    public string? Width { get; set; }

    /// <summary>
    /// When true, the column header is clickable and toggles sort direction.
    /// </summary>
    public bool Sortable { get; set; }

    /// <summary>
    /// Custom cell template. Receives the <typeparamref name="TItem"/> as context.
    /// When null, the field value is rendered as plain text.
    /// </summary>
    public RenderFragment<TItem>? Template { get; set; }

    /// <summary>
    /// Optional CSS class added to every <c>&lt;td&gt;</c> in this column.
    /// </summary>
    public string? CssClass { get; set; }

    internal string? GetFieldName()
    {
        if (Field == null) return null;
        if (Field.Body is MemberExpression member)
            return member.Member.Name;
        if (Field.Body is UnaryExpression unary && unary.Operand is MemberExpression member2)
            return member2.Member.Name;
        return null;
    }

    internal string? GetFieldValue(TItem item)
    {
        if (Field == null) return null;
        try
        {
            var compiled = Field.Compile();
            var val = compiled(item);
            return val?.ToString();
        }
        catch
        {
            return null;
        }
    }
}
