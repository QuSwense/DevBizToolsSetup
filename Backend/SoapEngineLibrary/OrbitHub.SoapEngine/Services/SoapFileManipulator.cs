using System;
using System.Xml.Linq;
using OrbitHub.SoapEngine.Models;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapFileManipulator
{
    private XDocument _xmlDocument;

    public async Task Process(SoapFileLoadInput soapFile)
    {
        // Implementation for processing the SOAP file, such as validating, minifying, or extracting relevant information
        _xmlDocument = XDocument.Parse(soapFile.Content);

        await ExtractBinaries();
    }

    public async Task ExtractBinaries()
    {
        // Implementation for extracting binaries from the compressed data
        // Example: Extract all binary elements from the XML document
        var binaryElements = _xmlDocument.Descendants("Binary");
        foreach (var binaryElement in binaryElements)
        {
            var base64Content = binaryElement.Value;
            var binaryData = Convert.FromBase64String(base64Content);
            // Process the binary data as needed
        }
    }
}
