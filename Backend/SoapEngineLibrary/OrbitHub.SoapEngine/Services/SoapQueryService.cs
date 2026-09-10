using OrbitHub.Data.ServiceAppManagement;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapQueryService(
    ServiceApplicationRepository appRepository,
    ServiceOperationRepository operationRepository,
    ServiceRequestFileRepository requestFileRepository,
    ServiceExecutionAuditRepository executionRepository)
{
    public async Task<PagedResultModel<ServiceApplication>> GetApplicationsAsync(
        ApplicationFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await appRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceOperation>> GetOperationsAsync(
        OperationFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await operationRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceRequestFile>> GetRequestFilesAsync(
        RequestFileFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await requestFileRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<DirectExecutionAudit>> GetExecutionAuditsAsync(
        ExecutionAuditFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetAuditsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<DirectExecutionAuditResponseFileLink>> GetExecutionLinksAsync(
        ExecutionAuditLinkFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseLinksPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceResponseFile>> GetResponseFilesAsync(
        int? serviceRequestFileId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseFilesPagedAsync(serviceRequestFileId, pageNumber, pageSize, cancellationToken);
    }
}