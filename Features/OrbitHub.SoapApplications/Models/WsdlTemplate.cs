namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A template for generating SOAP request files with {{var_name}} placeholders.
/// A template can extend another template to inherit its content and variables.
/// </summary>
public class WsdlTemplate
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    /// <summary>
    /// The WSDL file name (e.g. "wsdl_basic.wsdl") referenced by this template.
    /// The actual WSDL content is loaded from the database.
    /// </summary>
    public string Content { get; set; } = "";
    public string? ExtendsTemplateId { get; set; }
    public string? ExtendsTemplateName { get; set; }
    public string[] Variables { get; set; } = [];
    public string CreatedBy { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public string? UpdatedBy { get; set; }
    public string? UpdatedAt { get; set; }
}
