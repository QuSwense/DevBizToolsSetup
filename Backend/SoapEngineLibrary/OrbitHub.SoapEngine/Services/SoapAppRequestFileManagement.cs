using System;
using System.Xml;
using OrbitHub.GenericModels;
using OrbitHub.SoapEngine.Models;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapAppRequestFileManagement
{
    private string MinifyXml(string xmlContent)
    {
        // Validate the XML content
        xmlContent.NotNullOrWhiteSpace();

        // Reformat the XML using XML parsing and writing techniques to remove unnecessary whitespace and line breaks
        // Example: Use an XML library to parse and write the XML content in a minified format
        XmlDocument xmlDoc = new();
        xmlDoc.LoadXml(xmlContent);
        using StringWriter stringWriter = new();
        using XmlTextWriter xmlTextWriter = new(stringWriter);
        xmlTextWriter.Formatting = Formatting.None;
        xmlDoc.WriteTo(xmlTextWriter);
        xmlContent = stringWriter.ToString();

        return xmlContent; // Placeholder, replace with actual minification logic
    }

    public void SaveRequestFile(SoapRequestFileLoadInput requestFile)
    {
        // Validate the request file input
        requestFile.Name.NotNullOrWhiteSpace();
        requestFile.Content.NotNullOrWhiteSpace();

        // Convert the xml text ontent into a minified standard format
        // This is will help compare any xml file directly
        requestFile.Content = MinifyXml(requestFile.Content);

        // Check if a similar blob exists if requested
        if (requestFile.CheckSimilarBlob)
        {
            // Implement logic to check for similar blobs
        }

        // Implement logic to save the request file
        // Overwrite existing file by name if requested
        if (requestFile.OverwriteExistingByName)
        {
            // Implement logic to overwrite existing file by name
        }
    }

    public byte[] GetRequestFile(int soapRequestFileId)
    {
        // Implement logic to retrieve the request file
        return Array.Empty<byte>();
    }

    public void DeleteRequestFile(int soapRequestFileId)
    {
        // Implement logic to delete the request file
    }

    public bool RequestFileExists(int soapRequestFileId)
    {
        // Implement logic to check if the request file exists
        return false;
    }
}
