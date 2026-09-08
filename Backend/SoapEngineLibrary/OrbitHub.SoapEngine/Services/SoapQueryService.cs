using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

namespace ServiceHub.SoapEngine.Core.Services;

public class SoapQueryService(
    ServiceApplicationRepository appRepository,
    ServiceOperationRepository operationRepository,
    ServiceRequestFileRepository requestFileRepository,
    ServiceExecutionAuditRepository executionRepository)
{
    public async Task<PagedResult<ServiceApplication>> GetApplicationsAsync(
        ApplicationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await appRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<ServiceOperation>> GetOperationsAsync(
        OperationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await operationRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<ServiceRequestFile>> GetRequestFilesAsync(
        RequestFileFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await requestFileRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<DirectExecutionAudit>> GetExecutionAuditsAsync(
        ExecutionAuditFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetAuditsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<DirectExecutionAuditResponseFileLink>> GetExecutionLinksAsync(
        ExecutionAuditLinkFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseLinksPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<ServiceResponseFile>> GetResponseFilesAsync(
        int? serviceRequestFileId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseFilesPagedAsync(serviceRequestFileId, pageNumber, pageSize, cancellationToken);
    }
}