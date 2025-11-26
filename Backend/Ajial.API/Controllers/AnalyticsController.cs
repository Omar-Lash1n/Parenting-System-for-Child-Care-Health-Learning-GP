using Ajial.Application.DTOs.Analytics;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;
    private readonly ILogger<AnalyticsController> _logger;

    public AnalyticsController(
        IAnalyticsService analyticsService,
        ILogger<AnalyticsController> logger)
    {
        _analyticsService = analyticsService;
        _logger = logger;
    }

    /// <summary>
    /// Get all children with full details (Flat structure for Power BI)
    /// </summary>
    /// <remarks>
    /// Returns all children data with parent and city information in flat structure.
    /// Perfect for Power BI table import.
    /// 
    /// Each row contains:
    /// - All child fields (ID, name, age, gender, etc.)
    /// - Parent information (ID, name, email, etc.)
    /// - City information
    /// - Calculated fields (age group, days since registration, etc.)
    /// </remarks>
    [HttpGet("children")]
    [AllowAnonymous] // Change to [Authorize] if you want to protect it
    [ProducesResponseType(typeof(ApiResponse<List<ChildAnalyticsDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetAllChildrenAnalytics()
    {
        try
        {
            _logger.LogInformation("Fetching all children analytics data");

            var result = await _analyticsService.GetAllChildrenAnalyticsAsync();

            if (!result.Success)
            {
                _logger.LogWarning("Failed to fetch children analytics. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return StatusCode(500, result);
            }

            _logger.LogInformation("Successfully fetched {Count} children records",
                result.Data?.Count ?? 0);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAllChildrenAnalytics endpoint");
            return StatusCode(500, ApiResponse<List<ChildAnalyticsDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب البيانات" }
            ));
        }
    }

    /// <summary>
    /// Get parents with their children (Flat structure for Power BI)
    /// </summary>
    /// <remarks>
    /// Returns parent-children relationships in flat structure.
    /// One row per parent-child relationship.
    /// 
    /// Each row contains:
    /// - Parent full information
    /// - Parent statistics (total children, active children, etc.)
    /// - Child information (one child per row)
    /// - City information
    /// 
    /// Parents with no children will have one row with null child fields.
    /// </remarks>
    [HttpGet("parents-children")]
    [AllowAnonymous] // Change to [Authorize] if you want to protect it
    [ProducesResponseType(typeof(ApiResponse<List<ParentChildrenFlatDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetParentsWithChildrenFlat()
    {
        try
        {
            _logger.LogInformation("Fetching parents with children (flat structure)");

            var result = await _analyticsService.GetParentsWithChildrenFlatAsync();

            if (!result.Success)
            {
                _logger.LogWarning("Failed to fetch parents-children data. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return StatusCode(500, result);
            }

            _logger.LogInformation("Successfully fetched {Count} parent-child records",
                result.Data?.Count ?? 0);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetParentsWithChildrenFlat endpoint");
            return StatusCode(500, ApiResponse<List<ParentChildrenFlatDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب البيانات" }
            ));
        }
    }
}