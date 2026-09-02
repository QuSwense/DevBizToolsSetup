namespace SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;
using ServiceHub.SoapEngine.Core.Services;

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
        await ExecuteSafelyAsync("GetExecutionGroups", Test_GetExecutionGroups);
        await ExecuteSafelyAsync("GetExecutionRuns", Test_GetExecutionRuns);
        await ExecuteSafelyAsync("GetResponseFiles", Test_GetResponseFiles);
        await ExecuteSafelyAsync("QueryService Methods", Test_QueryServiceMethods);
    }

    private static async Task ExecuteSafelyAsync(string testName, Func<Task> testAction)
    {
        try
        {
            await testAction();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] '{testName}' threw unhandled exception: {ex.GetType().Name} - {ex.Message}");
        }
    }

    public async Task Test_GetApplications()
    {
        logger.LogInformation("TEST: Retrieving paged applications...");
        var filter = new ApplicationFilter
        {
            PageNumber = 1,
            PageSize = 5,
            SortBy = "CreatedAt",
            SortDescending = true
        };
        var result = await appService.GetApplicationsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} apps, returned {result.Items.Count} on page 1.");
        if (result.Items.Count > 0)
            Console.WriteLine($"    First: {result.Items.First().AppName} (ID: {result.Items.First().Id})");
    }

    public async Task Test_GetOperations()
    {
        logger.LogInformation("TEST: Retrieving paged operations...");
        var filter = new OperationFilter
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
        var filter = new RequestFileFilter
        {
            PageNumber = 1,
            PageSize = 5,
            IsActive = true
        };
        var result = await appService.GetRequestFilesAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} active request files.");
    }

    public async Task Test_GetExecutionGroups()
    {
        logger.LogInformation("TEST: Retrieving paged execution groups...");
        var filter = new ExecutionGroupFilter
        {
            PageNumber = 1,
            PageSize = 5,
            IsActive = true
        };
        var result = await appService.GetExecutionGroupsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} active execution groups.");
    }

    public async Task Test_GetExecutionRuns()
    {
        logger.LogInformation("TEST: Retrieving paged execution runs...");
        var filter = new ExecutionRunFilter
        {
            PageNumber = 1,
            PageSize = 5
        };
        var result = await appService.GetExecutionRunsAsync(filter);
        Console.WriteLine($" -> Found {result.TotalCount} execution runs.");
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
        var appResult = await queryService.GetApplicationsAsync(new ApplicationFilter { PageSize = 1 });
        var opResult = await queryService.GetOperationsAsync(new OperationFilter { PageSize = 1 });
        var fileResult = await queryService.GetRequestFilesAsync(new RequestFileFilter { PageSize = 1 });
        var groupResult = await queryService.GetExecutionGroupsAsync(new ExecutionGroupFilter { PageSize = 1 });
        var runResult = await queryService.GetExecutionRunsAsync(new ExecutionRunFilter { PageSize = 1 });
        var responseResult = await queryService.GetResponseFilesAsync(null, 1, 1);

        if (appResult is not null && opResult is not null && fileResult is not null &&
            groupResult is not null && runResult is not null && responseResult is not null)
        {
            Console.WriteLine(" [PASS] All SoapQueryService methods returned results.");
        }
        else
        {
            Console.WriteLine(" [FAIL] One or more query methods failed.");
        }
    }
}