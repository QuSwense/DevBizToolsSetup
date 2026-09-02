using Microsoft.Extensions.Logging;
using PdfSharpCore.Pdf;
using PdfSharpCore.Pdf.AcroForms;
using PdfSharpCore.Pdf.IO;
using PdfProcessor.Exceptions;
using PdfProcessor.Models.Editor;

namespace PdfProcessor.Services;

public sealed class PdfEditorContext : IDisposable, IAsyncDisposable
{
    private readonly MemoryStream _workingStream;
    private readonly PdfDocument _pdfDocument;
    private readonly ILogger<PdfEditorContext>? _logger;
    private bool _disposed;

    public bool IsDirty { get; private set; }

    private PdfEditorContext(Stream sourceStream, ILogger<PdfEditorContext>? logger = null)
    {
        ArgumentNullException.ThrowIfNull(sourceStream);
        if (!sourceStream.CanRead)
            throw new PdfProcessingException("Source PDF stream is not readable.", "StreamValidation");

        _logger = logger;
        _workingStream = new MemoryStream();
        sourceStream.CopyTo(_workingStream);
        _workingStream.Position = 0;

        // Open document in Modify mode using PdfSharpCore
        _pdfDocument = PdfReader.Open(_workingStream, PdfDocumentOpenMode.Modify);
    }

    public static async Task<PdfEditorContext> CreateAsync(
        Stream sourceStream,
        ILogger<PdfEditorContext>? logger = null,
        CancellationToken cancellationToken = default)
    {
        return await Task.Run(() => new PdfEditorContext(sourceStream, logger), cancellationToken);
    }

    /// <summary>
    /// Sets text field or combo choice value.
    /// </summary>
    public FormFieldUpdateResult SetFieldValue(string fieldName, string newValue)
    {
        EnsureNotDisposed();

        var field = GetAcroField(fieldName);
        if (field == null)
        {
            return new(fieldName, false, StatusMessage: $"Field '{fieldName}' not found.");
        }

        if (field is PdfTextField textField)
        {
            string oldValue = textField.Text;

            try
            {
                // Try standard appearance rendering first
                textField.Text = newValue;
            }
            catch (NullReferenceException)
            {
                // Fallback: Directly assign underlying dictionary key '/V' if font/appearance reference is missing
                textField.Elements.SetString("/V", newValue);
            }

            IsDirty = true;
            return new(fieldName, true, oldValue, newValue, "Success");
        }

        if (field is PdfComboBoxField comboField)
        {
            string oldValue = comboField.Value?.ToString() ?? string.Empty;
            comboField.Elements.SetString("/V", newValue);
            IsDirty = true;
            return new(fieldName, true, oldValue, newValue, "Success");
        }

        return new(fieldName, false, StatusMessage: "Unsupported field type for text assignment.");
    }

    /// <summary>
    /// Sets checkbox or radio option state.
    /// </summary>
    public FormFieldUpdateResult SetCheckState(string fieldName, bool isChecked)
    {
        EnsureNotDisposed();

        var field = GetAcroField(fieldName);
        if (field == null)
        {
            return new(fieldName, false, StatusMessage: $"Field '{fieldName}' not found.");
        }

        if (field is PdfCheckBoxField checkBox)
        {
            try
            {
                // Standard assignment
                checkBox.Checked = isChecked;
            }
            catch (Exception)
            {
                // Direct dictionary fallback: determine off vs on state name
                // '/Off' is standard unchecked; for checked, default to '/Yes' or fallback to '/0'
                string exportName = isChecked ? "/0" : "/Off";
                checkBox.Elements.SetName("/V", exportName);
                checkBox.Elements.SetName("/AS", exportName);
            }

            IsDirty = true;
            return new(fieldName, true, StatusMessage: "Success");
        }

        return new(fieldName, false, StatusMessage: "Field is not a check box.");
    }

    /// <summary>
    /// Renames an AcroForm field.
    /// </summary>
    public FormFieldUpdateResult RenameField(string currentFieldName, string newFieldName)
    {
        EnsureNotDisposed();
        ArgumentException.ThrowIfNullOrWhiteSpace(newFieldName);

        var field = GetAcroField(currentFieldName);
        if (field == null)
        {
            return new(currentFieldName, false, StatusMessage: $"Field '{currentFieldName}' not found.");
        }

        // Update the /T key in the underlying PDF dictionary
        field.Elements.SetString("/T", newFieldName);
        IsDirty = true;
        return new(currentFieldName, true, currentFieldName, newFieldName, "Field successfully renamed.");
    }

    private static string GetCheckBoxOnStateName(PdfCheckBoxField checkBox)
    {
        // Access nested AP -> N dictionaries via .Elements.GetDictionary(...)
        if (checkBox.Elements.GetDictionary("/AP")?.Elements.GetDictionary("/N") is PdfDictionary apDict)
        {
            foreach (var key in apDict.Elements.Keys)
            {
                if (!string.Equals(key, "/Off", StringComparison.OrdinalIgnoreCase))
                {
                    return key; // e.g., "/0", "/Yes", "/1"
                }
            }
        }

        return "/Yes"; // Default fallback if key isn't found
    }

    private PdfAcroField? GetAcroField(string fieldName)
    {
        var form = _pdfDocument.AcroForm;
        if (form == null) return null;

        return form.Fields[fieldName];
    }

    private void EnsureNotDisposed()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
    }

    public void Dispose()
    {
        if (_disposed) return;
        _pdfDocument?.Dispose();
        _workingStream?.Dispose();
        _disposed = true;
    }

    public ValueTask DisposeAsync()
    {
        Dispose();
        return ValueTask.CompletedTask;
    }

    #region Save & Export API

    /// <summary>
    /// Saves the edited PDF document directly to a file path with options for custom naming and overwriting existing files.
    /// </summary>
    /// <param name="destinationPath">Target directory path or full target file path.</param>
    /// <param name="newFileName">Optional new file name (e.g., "Updated_Document.pdf"). If omitted, uses the filename specified in target path.</param>
    /// <param name="overwrite">If true, overwrites any existing file at the final target path; otherwise throws IOException.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The full path of the saved file.</returns>
    public async Task<string> SaveAsync(
        string destinationPath,
        string? newFileName = null,
        bool overwrite = false,
        CancellationToken cancellationToken = default)
    {
        EnsureNotDisposed();
        ArgumentException.ThrowIfNullOrWhiteSpace(destinationPath);

        string targetFilePath;

        // Determine target path based on whether destinationPath is a directory or full file path
        if (Directory.Exists(destinationPath) || string.IsNullOrEmpty(Path.GetExtension(destinationPath)))
        {
            string fileName = !string.IsNullOrWhiteSpace(newFileName)
                ? newFileName
                : "output_edited.pdf";

            if (!fileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            {
                fileName += ".pdf";
            }

            targetFilePath = Path.Combine(destinationPath, fileName);
        }
        else
        {
            // Destination path contains a file name
            if (!string.IsNullOrWhiteSpace(newFileName))
            {
                string directory = Path.GetDirectoryName(destinationPath) ?? AppContext.BaseDirectory;
                string fileName = newFileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)
                    ? newFileName
                    : newFileName + ".pdf";

                targetFilePath = Path.Combine(directory, fileName);
            }
            else
            {
                targetFilePath = destinationPath;
            }
        }

        // Handle overwrite checks
        if (File.Exists(targetFilePath) && !overwrite)
        {
            throw new IOException($"File already exists at target path '{targetFilePath}' and overwrite is set to false.");
        }

        // Ensure target directory exists
        string? targetDirectory = Path.GetDirectoryName(targetFilePath);
        if (!string.IsNullOrEmpty(targetDirectory) && !Directory.Exists(targetDirectory))
        {
            Directory.CreateDirectory(targetDirectory);
        }

        // Open file stream and delegate to stream-based SaveAsync
        var mode = overwrite ? FileMode.Create : FileMode.CreateNew;
        await using var fileStream = new FileStream(targetFilePath, mode, FileAccess.Write, FileShare.None);
        await SaveAsync(fileStream, cancellationToken);

        return targetFilePath;
    }

    /// <summary>
    /// Exports the edited document into the destination output stream.
    /// </summary>
    public async Task SaveAsync(Stream outputDestination, CancellationToken cancellationToken = default)
    {
        EnsureNotDisposed();
        ArgumentNullException.ThrowIfNull(outputDestination);

        if (!outputDestination.CanWrite)
            throw new PdfProcessingException("Destination output stream is not writable.", "SaveAsync");

        await Task.Run(() =>
        {
            try
            {
                _pdfDocument.Save(outputDestination, false);
                IsDirty = false;
                _logger?.LogInformation("Successfully saved updated PDF document.");
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Failed to save edited PDF document.");
                throw new PdfProcessingException("Error saving modified PDF stream.", "SaveAsync", ex);
            }
        }, cancellationToken);
    }

    #endregion
}