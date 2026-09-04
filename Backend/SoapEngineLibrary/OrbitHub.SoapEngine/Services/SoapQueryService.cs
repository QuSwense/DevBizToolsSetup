using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

namespace ServiceHub.SoapEngine.Core.Services;

public class SoapQueryService(
    SoapApplicationRepository appRepository,
    SoapOperationRepository operationRepository,
    SoapRequestFileRepository requestFileRepository,
    SoapExecutionRepository executionRepository)
{
    public async Task<PagedResult<SoapApplication>> GetApplicationsAsync(
        ApplicationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await appRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapOperation>> GetOperationsAsync(
        OperationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await operationRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapRequestFile>> GetRequestFilesAsync(
        RequestFileFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await requestFileRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapExecutionGroup>> GetExecutionGroupsAsync(
        ExecutionGroupFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetGroupsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapExecutionRun>> GetExecutionRunsAsync(
        ExecutionRunFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetRunsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapResponseFile>> GetResponseFilesAsync(
        int? executionItemRunId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseFilesPagedAsync(executionItemRunId, pageNumber, pageSize, cancellationToken);
    }
}