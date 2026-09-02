namespace PdfProcessor.TestRunner.Abstractions;

public interface ITestRunner
{
    string TargetFileName { get; }
    Task RunAsync(string basePdfDirectory);
}