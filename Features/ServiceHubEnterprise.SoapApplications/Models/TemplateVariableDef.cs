namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// Describes a variable extracted from a template for the dynamic form.
/// </summary>
public class TemplateVariableDef
{
    public string Name { get; set; } = "";
    public string Label { get; set; } = "";
    public string DefaultValue { get; set; } = "";
    public string InputType { get; set; } = "text"; // "text" | "textarea" | "select"
    public string[] Options { get; set; } = [];
}
