using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Home;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/parent/home")]
public class ParentHomeController : ControllerBase
{
    private readonly IParentHomeService _parentHomeService;
    private readonly ILogger<ParentHomeController> _logger;

    public ParentHomeController(
        IParentHomeService parentHomeService,
        ILogger<ParentHomeController> logger)
    {
        _parentHomeService = parentHomeService;
        _logger = logger;
    }

    /// <summary>
    /// التطعيمات الحالية - Get current vaccinations for parent's children
    /// </summary>
    [HttpGet("current-vaccinations")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetCurrentVaccinationsResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCurrentVaccinations()
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<GetCurrentVaccinationsResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }));
            }

            _logger.LogInformation("User {UserId} requesting current vaccinations for home page", userId);

            var result = await _parentHomeService.GetCurrentVaccinationsAsync(userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetCurrentVaccinations endpoint");
            return StatusCode(500, ApiResponse<GetCurrentVaccinationsResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }));
        }
    }

    /// <summary>
    /// المهام القادمة - Get upcoming tasks for parent home page
    /// </summary>
    [HttpGet("upcoming-tasks")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetUpcomingTasksResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetUpcomingTasks([FromQuery] int limit = 5)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<GetUpcomingTasksResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }));
            }

            _logger.LogInformation(
                "User {UserId} requesting upcoming tasks for home page (limit: {Limit})",
                userId, limit);

            var result = await _parentHomeService.GetUpcomingTasksAsync(userId, limit);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetUpcomingTasks endpoint");
            return StatusCode(500, ApiResponse<GetUpcomingTasksResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }));
        }
    }
}
