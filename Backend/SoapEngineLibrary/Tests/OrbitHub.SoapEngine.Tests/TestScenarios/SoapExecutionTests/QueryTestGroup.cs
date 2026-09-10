namespace OrbitHub.SoapEngine.Tests.TestScenarios.SoapExecutionTests;

using Microsoft.Extensions.Logging;
using OrbitHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;
using static SoapApiProcessorTest.Helpers.TestHelper;

public class QueryTestGroup(
    SoapApplicationService appService,
    SoapQueryService queryService,
    ILogger<QueryTestGroup> logger)
{
    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    12. QUERY/PAGED RETRIEVAL TEST GROUP         ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("GetApplications", Test_GetApplications);
        await ExecuteSafelyAsync("GetOperations", Test_GetOperations);
        await ExecuteSafelyAsync("GetRequestFiles", Test_GetRequestFiles);
        await ExecuteSafelyAsync("GetExecutionAudits", Test_GetExecutionAudits);
        await ExecuteSafelyAsync("GetExecutionLinks", Test_GetExecutionLinks);
        await ExecuteSafelyAsync("GetResponseFiles", Test_GetResponseFiles);
        await ExecuteSafelyAsync("QueryService Methods", Test_QueryServiceMethods);
    }

    public async Task Test_GetApplications()
    {
        logger.LogInformation("TEST: Retrieving paged applications...");
        var filter = new ApplicationFilterModel
        {
            PageNumber = 1,
            PageSize = 5,
            SortBy = "CreatedAt",
            SortDescending = true
        };
        var result = await appService.GetApplicationsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} apps, returned {result.Items.Count} on page 1.");
        if (result.Items.Count > 0)
            Console.WriteLine($"    First: {result.Items.First().Name} (ID: {result.Items.First().Id})");
    }

    public async Task Test_GetOperations()
    {
        logger.LogInformation("TEST: Retrieving paged operations...");
        var filter = new OperationFilterModel
        {
            PageNumber = 1,
            PageSize = 5,
            IsActive = true
        };
        var result = await appService.GetOperationsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} active operations.");
    }

    public async Task Test_GetRequestFiles()
    {
        logger.LogInformation("TEST: Retrieving paged request files...");
        var filter = new RequestFileFilterModel
        {
            PageNumber = 1,
            PageSize = 5,
            IsActive = true
        };
        var result = await appService.GetRequestFilesAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} active request files.");
    }

    public async Task Test_GetExecutionAudits()
    {
        logger.LogInformation("TEST: Retrieving paged execution audits...");
        var filter = new ExecutionAuditFilterModel
        {
            PageNumber = 1,
            PageSize = 5
        };
        var result = await appService.GetExecutionAuditsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} execution audits.");
    }

    public async Task Test_GetExecutionLinks()
    {
        logger.LogInformation("TEST: Retrieving paged execution links...");
        var filter = new ExecutionAuditLinkFilterModel
        {
            PageNumber = 1,
            PageSize = 5
        };
        var result = await appService.GetExecutionLinksAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} execution links.");
    }

    public async Task Test_GetResponseFiles()
    {
        logger.LogInformation("TEST: Retrieving paged response files...");
        var result = await appService.GetResponseFilesAsync(null, 1, 5);
        Console.WriteLine($" -> Found {result.TotalCount} response files.");
    }

    public async Task Test_QueryServiceMethods()
    {
        logger.LogInformation("TEST: Verifying SoapQueryService methods...");
        var appResult = await queryService.GetApplicationsAsync(new ApplicationFilterModel { PageSize = 1 });
        var opResult = await queryService.GetOperationsAsync(new OperationFilterModel { PageSize = 1 });
        var fileResult = await queryService.GetRequestFilesAsync(new RequestFileFilterModel { PageSize = 1 });
        var auditResult = await queryService.GetExecutionAuditsAsync(new ExecutionAuditFilterModel { PageSize = 1 });
        var linkResult = await queryService.GetExecutionLinksAsync(new ExecutionAuditLinkFilterModel { PageSize = 1 });
        var responseResult = await queryService.GetResponseFilesAsync(null, 1, 1);

        if (appResult is not null && opResult is not null && fileResult is not null &&
            auditResult is not null && linkResult is not null && responseResult is not null)
        {
            Console.WriteLine(" [PASS] All SoapQueryService methods returned results.");
        }
        else
        {
            Console.WriteLine(" [FAIL] One or more query methods failed.");
        }
    }
}