using System.Xml;
using System.Xml.Linq;
using ServiceHub.SoapEngine.Core.Exceptions;
using ServiceHub.SoapEngine.Core.Parsing.Models;

namespace ServiceHub.SoapEngine.Core.Parsing;

public class WsdlParser(HttpClient httpClient)
{
    private static readonly XNamespace Wsdl11Ns = "http://schemas.xmlsoap.org/wsdl/";
    private static readonly XNamespace Soap11Ns = "http://schemas.xmlsoap.org/wsdl/soap/";
    private static readonly XNamespace Soap12Ns = "http://schemas.xmlsoap.org/wsdl/soap12/";
    private static readonly XNamespace XsdNs = "http://www.w3.org/2001/XMLSchema";

    public async Task<ParsedWsdlMetadata> FetchAndParseAsync(
        string wsdlUrl,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await httpClient.GetAsync(wsdlUrl, cancellationToken);
            response.EnsureSuccessStatusCode();
            string rawWsdlContent = await response.Content.ReadAsStringAsync(cancellationToken);
            var parsed = ParseContent(rawWsdlContent);
            return parsed;
        }
        catch (Exception ex) when (ex is not WsdlParsingException)
        {
            throw new WsdlParsingException($"Failed to fetch WSDL from URL: {wsdlUrl}", wsdlUrl, ex);
        }
    }

    public ParsedWsdlMetadata ParseContent(string rawWsdlContent)
    {
        if (string.IsNullOrWhiteSpace(rawWsdlContent))
            throw new WsdlParsingException("WSDL content cannot be null or empty.");

        try
        {
            var doc = XDocument.Parse(rawWsdlContent);
            var root = doc.Root
                ?? throw new WsdlParsingException("Invalid XML document: Root element missing.");

            var result = new ParsedWsdlMetadata
            {
                RawWsdlContent = rawWsdlContent,
                Namespaces = ExtractNamespaces(root),
                ExtractedXsdSchemas = ExtractInlineSchemas(root),
                TargetNamespace = root.Attribute("targetNamespace")?.Value   // NEW
            };

            result.Operations = ExtractOperations(root, result.TargetNamespace); // Pass target NS
            return result;
        }
        catch (XmlException ex)
        {
            throw new WsdlParsingException("Malformed XML syntax in WSDL document.", ex);
        }
    }

    private static Dictionary<string, string> ExtractNamespaces(XElement root)
    {
        var namespaces = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var attr in root.Attributes())
        {
            if (attr.IsNamespaceDeclaration)
            {
                string prefix = attr.Name.LocalName == "xmlns" ? "default" : attr.Name.LocalName;
                if (!namespaces.ContainsKey(prefix))
                    namespaces[prefix] = attr.Value;
            }
        }
        return namespaces;
    }

    private static List<string> ExtractInlineSchemas(XElement root)
    {
        var schemas = new List<string>();
        var typesElement = root.Element(Wsdl11Ns + "types");
        if (typesElement is not null)
        {
            var schemaElements = typesElement.Elements(XsdNs + "schema");
            foreach (var schema in schemaElements)
                schemas.Add(schema.ToString(SaveOptions.None));
        }
        return schemas;
    }

    private static List<ParsedOperationMetadata> ExtractOperations(XElement root, string? targetNamespace)
    {
        var operations = new List<ParsedOperationMetadata>();
        var soapActionMap = BuildSoapActionMap(root);
        var messageElementMap = BuildMessageElementMap(root);

        var portTypes = root.Elements(Wsdl11Ns + "portType");
        foreach (var portType in portTypes)
        {
            var opElements = portType.Elements(Wsdl11Ns + "operation");
            foreach (var op in opElements)
            {
                string? opName = op.Attribute("name")?.Value;
                if (string.IsNullOrWhiteSpace(opName)) continue;

                string? soapAction = soapActionMap.TryGetValue(opName, out var action) ? action : null;

                var inputMessageAttr = op.Element(Wsdl11Ns + "input")?.Attribute("message")?.Value;
                var outputMessageAttr = op.Element(Wsdl11Ns + "output")?.Attribute("message")?.Value;

                string? inputRoot = ResolveElementFromMessage(inputMessageAttr, messageElementMap);
                string? outputRoot = ResolveElementFromMessage(outputMessageAttr, messageElementMap);

                operations.Add(new ParsedOperationMetadata
                {
                    OperationName = opName,
                    SoapAction = soapAction,
                    InputRootElementName = inputRoot ?? opName,
                    OutputRootElementName = outputRoot ?? $"{opName}Response",
                    TargetNamespace = targetNamespace   // NEW
                });
            }
        }
        return operations;
    }

    private static Dictionary<string, string> BuildSoapActionMap(XElement root)
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var bindings = root.Elements(Wsdl11Ns + "binding");
        foreach (var binding in bindings)
        {
            var bindingOps = binding.Elements(Wsdl11Ns + "operation");
            foreach (var bOp in bindingOps)
            {
                string? opName = bOp.Attribute("name")?.Value;
                if (string.IsNullOrWhiteSpace(opName)) continue;

                var soapOp11 = bOp.Element(Soap11Ns + "operation");
                var soapOp12 = bOp.Element(Soap12Ns + "operation");
                string? action = soapOp11?.Attribute("soapAction")?.Value
                              ?? soapOp12?.Attribute("soapAction")?.Value;

                if (!string.IsNullOrWhiteSpace(action) && !map.ContainsKey(opName))
                    map[opName] = action;
            }
        }
        return map;
    }

    private static Dictionary<string, string> BuildMessageElementMap(XElement root)
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var messages = root.Elements(Wsdl11Ns + "message");
        foreach (var msg in messages)
        {
            string? msgName = msg.Attribute("name")?.Value;
            if (string.IsNullOrWhiteSpace(msgName)) continue;

            var part = msg.Element(Wsdl11Ns + "part");
            string? elementName = part?.Attribute("element")?.Value;
            if (!string.IsNullOrWhiteSpace(elementName))
            {
                int colonIndex = elementName.IndexOf(':');
                if (colonIndex >= 0)
                    elementName = elementName[(colonIndex + 1)..];
                map[msgName] = elementName;
            }
        }
        return map;
    }

    private static string? ResolveElementFromMessage(string? messageQName, Dictionary<string, string> messageMap)
    {
        if (string.IsNullOrWhiteSpace(messageQName)) return null;
        int colonIndex = messageQName.IndexOf(':');
        string localMsgName = colonIndex >= 0 ? messageQName[(colonIndex + 1)..] : messageQName;
        return messageMap.TryGetValue(localMsgName, out var elementName) ? elementName : localMsgName;
    }
}