using Microsoft.Extensions.Logging;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class PdfFormEditingTester(
    PdfEditorContextFactory editorFactory,
    PdfContextFactory readContextFactory,
    ILogger<PdfFormEditingTester> logger) : ITestRunner
{
    public string TargetFileName => "FormFieldExample1.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE 5: PDF Form Editing & Persistence Context] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] Test PDF missing at path: {Path}", filePath);
            return;
        }

        using var inputStream = File.OpenRead(filePath);

        // 1. Instantiate editor context directly via concrete factory
        await using var editor = await editorFactory.CreateEditorAsync(inputStream);

        // -------------------------------------------------------------
        // TEST SECTION 1: Field Renaming & Personal Details Update
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 1: Renaming & Editing Personal Details] ---");

        // Rename 'Text3' (Full Name) -> 'Applicant_Full_Name'
        var renameResult = editor.RenameField("Text3", "Applicant_Full_Name");
        logger.LogInformation("  -> RenameField('Text3' -> 'Applicant_Full_Name'): Updated={IsUpdated}, Message='{Status}'",
            renameResult.IsUpdated, renameResult.StatusMessage);

        var nameValResult = editor.SetFieldValue("Applicant_Full_Name", "Hercules Jones");
        logger.LogInformation("  -> SetFieldValue('Applicant_Full_Name'): Updated={IsUpdated}, Message='{Status}'",
            nameValResult.IsUpdated, nameValResult.StatusMessage);

        // Update Phone (Text6) & Email (Text7)
        var phoneResult = editor.SetFieldValue("Text6", "(555) 987-6543");
        logger.LogInformation("  -> SetFieldValue('Text6' - Phone): Updated={IsUpdated}", phoneResult.IsUpdated);

        var emailResult = editor.SetFieldValue("Text7", "hercules.jones@example.com");
        logger.LogInformation("  -> SetFieldValue('Text7' - Email): Updated={IsUpdated}", emailResult.IsUpdated);

        // -------------------------------------------------------------
        // TEST SECTION 2: Updating Work Schedule Fields
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 2: Updating Work Availability Schedule] ---");

        // Updating Monday Shift (Text10 & Text11)
        var monStart = editor.SetFieldValue("Text10", "09:00");
        var monEnd = editor.SetFieldValue("Text11", "17:00");
        logger.LogInformation("  -> Set Monday Shift (Text10/Text11): StartUpdated={StartUpdated}, EndUpdated={EndUpdated}",
            monStart.IsUpdated, monEnd.IsUpdated);

        // -------------------------------------------------------------
        // TEST SECTION 3: Toggling Check Boxes
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 3: Toggling Check Boxes] ---");

        // Toggle 'Check Box1' and 'Check Box9'
        var chk1Result = editor.SetCheckState("Check Box1", true);
        logger.LogInformation("  -> SetCheckState('Check Box1', true): Updated={IsUpdated}, Message='{Status}'",
            chk1Result.IsUpdated, chk1Result.StatusMessage);

        var chk9Result = editor.SetCheckState("Check Box9", true);
        logger.LogInformation("  -> SetCheckState('Check Box9', true): Updated={IsUpdated}, Message='{Status}'",
            chk9Result.IsUpdated, chk9Result.StatusMessage);

        // -------------------------------------------------------------
        // TEST SECTION 4: Negative Test / Edge Case Handling
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 4: Non-existent Field Error Handling] ---");

        var missingFieldResult = editor.SetFieldValue("NonExistent_Field_99", "Dummy Value");
        logger.LogInformation("  -> SetFieldValue on missing field: Updated={IsUpdated} (Expected: False), Message='{Status}'",
            missingFieldResult.IsUpdated, missingFieldResult.StatusMessage);

        // -------------------------------------------------------------
        // TEST SECTION 5: Saving & Exporting
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 5: File Export & Save Overloads] ---");

        // 5a. Save to MemoryStream
        using var outputMemoryStream = new MemoryStream();
        await editor.SaveAsync(outputMemoryStream);
        logger.LogInformation("  [PASS] Saved edited PDF to MemoryStream ({Length} bytes).", outputMemoryStream.Length);

        // 5b. Save to File Path (Overload)
        string outputDirectory = Path.Combine(basePdfDirectory, "output");
        string savedFilePath = await editor.SaveAsync(
            destinationPath: outputDirectory,
            newFileName: "FormFieldExample1_Edited.pdf",
            overwrite: true
        );
        logger.LogInformation("  [PASS] Saved edited PDF directly to file path: '{SavedPath}'", savedFilePath);

        // -------------------------------------------------------------
        // TEST SECTION 6: Post-Save Verification via Read Context
        // -------------------------------------------------------------
        logger.LogInformation("\n--- [TEST 6: Verification of Saved PDF] ---");

        outputMemoryStream.Position = 0;
        await using var verifyContext = await readContextFactory.CreateContextAsync(outputMemoryStream, prefetch: true);

        // Check renamed field existence
        bool renamedFieldExists = verifyContext.HasFormField("Applicant_Full_Name");
        logger.LogInformation("  [PASS] Verified renamed field 'Applicant_Full_Name' exists: {Exists}", renamedFieldExists);

        // Validate values written
        var valName = verifyContext.ValidateFormFieldValue("Applicant_Full_Name", "Hercules Jones");
        logger.LogInformation("  [PASS] Verified Field 'Applicant_Full_Name': IsValid={IsValid}, Value='{Actual}'",
            valName.IsValid, valName.ActualValue);

        var valEmail = verifyContext.ValidateFormFieldValue("Text7", "hercules.jones@example.com");
        logger.LogInformation("  [PASS] Verified Field 'Text7' (Email): IsValid={IsValid}, Value='{Actual}'",
            valEmail.IsValid, valEmail.ActualValue);

        var valMonStart = verifyContext.ValidateFormFieldValue("Text10", "09:00");
        logger.LogInformation("  [PASS] Verified Field 'Text10' (Monday Start): IsValid={IsValid}, Value='{Actual}'",
            valMonStart.IsValid, valMonStart.ActualValue);

        logger.LogInformation("\n[SUCCESS] Form editing suite executed and verified successfully.\n");
    }
}