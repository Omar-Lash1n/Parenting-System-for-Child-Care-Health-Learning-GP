using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ParentsController : ControllerBase
{
    private readonly IParentService _parentService;
    private readonly ILogger<ParentsController> _logger;

    public ParentsController(IParentService parentService, ILogger<ParentsController> logger)
    {
        _parentService = parentService;
        _logger = logger;
    }

    /// <summary>
    /// Get all parents data for analytics and Power BI
    /// </summary>
    /// <returns>Complete parent data including user info, demographics, and calculated metrics</returns>
    [HttpGet("analytics")]
    [ProducesResponseType(typeof(ApiResponse<List<ParentAnalyticsDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ParentAnalyticsDto>>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetParentsAnalytics()
    {
        try
        {
            _logger.LogInformation("Fetching all parents data for analytics at {Time}", DateTime.UtcNow);

            var result = await _parentService.GetAllParentsForAnalyticsAsync();

            if (result.Success)
            {
                _logger.LogInformation("Successfully retrieved {Count} parent records for analytics", 
                    result.Data?.Count ?? 0);
            }
            else
            {
                _logger.LogWarning("Failed to retrieve parents analytics data. Errors: {Errors}", 
                    string.Join(", ", result.Errors));
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetParentsAnalytics endpoint");
            return StatusCode(500, ApiResponse<List<ParentAnalyticsDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء استرجاع البيانات" }
            ));
        }
    }

    /// <summary>
    /// Get analytics summary statistics
    /// </summary>
    /// <returns>Summary statistics for Power BI dashboards</returns>
    [HttpGet("analytics/summary")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnalyticsSummary()
    {
        try
        {
            var result = await _parentService.GetAllParentsForAnalyticsAsync();

            if (!result.Success || result.Data == null)
            {
                return Ok(new
                {
                    success = false,
                    message = "No data available"
                });
            }

            var data = result.Data;

            var summary = new
            {
                success = true,
                message = "تم استرجاع الإحصائيات بنجاح",
                data = new
                {
                    totalParents = data.Count,
                    maleCount = data.Count(p => p.GenderCode == 1),
                    femaleCount = data.Count(p => p.GenderCode == 2),
                    averageAge = data.Any() ? (int)data.Average(p => p.Age) : 0,
                    ageGroups = data.GroupBy(p => p.AgeGroup)
                        .Select(g => new { ageGroup = g.Key, count = g.Count() })
                        .OrderBy(x => x.ageGroup),
                    citiesDistribution = data.GroupBy(p => p.CityName)
                        .Select(g => new { city = g.Key, count = g.Count() })
                        .OrderByDescending(x => x.count),
                    regionsDistribution = data.GroupBy(p => p.Region)
                        .Select(g => new { region = g.Key, count = g.Count() })
                        .OrderByDescending(x => x.count),
                    recentRegistrations = data.Where(p => p.AccountAgeInDays <= 30).Count(),
                    lastUpdated = DateTime.UtcNow
                }
            };

            return Ok(summary);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAnalyticsSummary endpoint");
            return StatusCode(500, new
            {
                success = false,
                message = "حدث خطأ في الخادم"
            });
        }
    }
}