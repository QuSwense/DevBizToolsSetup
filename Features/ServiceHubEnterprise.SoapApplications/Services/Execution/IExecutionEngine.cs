using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services.Execution;

/// <summary>
/// Abstraction over the SOAP execution pipeline. The simulated implementation
/// advances each file through a staged pipeline and produces request/response
/// artifacts; a real transport (HTTP to the app's BaseUrl) can be plugged in
/// later behind the same interface.
/// </summary>
public interface IExecutionEngine
{
    /// <summary>
    /// Creates a new execution group for the given request files with a unique
    /// group id (even a single file gets its own group).
    /// </summary>
    SoapExecutionGroup CreateGroup(IReadOnlyList<SoapRequestFile> files, string triggeredBy);

    /// <summary>
    /// Executes the group, advancing each file through the pipeline stages and
    /// reporting progress after each stage. Mutates the supplied group.
    /// </summary>
    Task RunAsync(
        SoapExecutionGroup group,
        IProgress<SoapExecutionGroup>? progress = null,
        CancellationToken cancellationToken = default);
}
