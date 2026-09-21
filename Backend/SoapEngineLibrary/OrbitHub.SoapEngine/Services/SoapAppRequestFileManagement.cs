using System;
using System.Xml;
using System.IO;
using OrbitHub.Data.ServiceAppManagement.Models;
using OrbitHub.Data.ServiceAppManagement.Repositories;
using OrbitHub.GenericModels;
using OrbitHub.SoapEngine.Models;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapAppRequestFileManagement(
    FindServiceRequestFileByOperationAndDataRepository _findServiceRequestFileByOperationAndDataRepository
)
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
        using XmlTextWriter xmlTextWriter = new(stringWriter)
        {
            Formatting = Formatting.None
        };
        xmlDoc.WriteTo(xmlTextWriter);
        xmlContent = stringWriter.ToString();

        return xmlContent; // Placeholder, replace with actual minification logic
    }

    public async Task<SoapFileLoadOutput> SaveRequestFileAsync(SoapFileLoadInput requestFile, CancellationToken ct)
    {
        // Validate the request file input
        requestFile.Name.NotNullOrWhiteSpace();
        requestFile.Content.NotNullOrWhiteSpace();

        // Convert the xml text ontent into a minified standard format
        // This is will help compare any xml file directly
        var textContent = MinifyXml(requestFile.Content);
        var binaryContent = System.Text.Encoding.UTF8.GetBytes(textContent);

        bool bFoundSimilarBlob = false;

        // Check if a similar blob exists if requested
        if (requestFile.CheckSimilarBlob)
        {
            // Implement logic to check for similar blobs call Find of FindServiceRequestFileByOperationAndDataRepository
            var input = new FindServiceRequestFileByOperationAndDataInput
            {
                ServiceOperationId = requestFile.ServiceOperationId,          // your value
                CompressedData     = binaryContent // your value
            };

            var result = await _findServiceRequestFileByOperationAndDataRepository.ExecuteAsync(input, ct);

            if (result.Success)
            {
                var output = result.Data;   // FindServiceRequestFileByOperationAndDataOutput?
                // use output...
                bFoundSimilarBlob = true;
            }
            else
            {
                // handle failure
                throw new Exception("Failed to execute the sp to find similar service request file.");
            }
        }

        // Implement logic to save the request file
        // Overwrite existing file by name if requested
        if (requestFile.OverwriteExistingByName)
        {
            // Implement logic to overwrite existing file by name
        }

        return new SoapFileLoadOutput
        {
            ServiceOperationId = requestFile.ServiceOperationId, // Replace with the actual ID after saving
            Name = requestFile.Name,
            SimilarBlobFound = bFoundSimilarBlob,
            SameNameExists = false // Replace with actual logic if needed
        };
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
