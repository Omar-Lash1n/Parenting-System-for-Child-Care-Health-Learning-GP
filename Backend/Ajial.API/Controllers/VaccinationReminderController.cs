using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.VaccinationReminder;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>
/// Endpoints for the "تفاصيل الموعد" vaccination reminder page.
/// All endpoints require the parent to be authenticated via JWT.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VaccinationReminderController : ControllerBase
{
    private readonly IVaccinationReminderService _reminderService;
    private readonly ILogger<VaccinationReminderController> _logger;

    public VaccinationReminderController(
        IVaccinationReminderService reminderService,
        ILogger<VaccinationReminderController> logger)
    {
        _reminderService = reminderService;
        _logger = logger;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /api/VaccinationReminder/device-token
    // Flutter calls this right after login to register the phone's FCM token
    // ─────────────────────────────────────────────────────────────────────────
    /// <summary>
    /// Register or update the FCM device token for the logged-in user.
    /// The Flutter app must call this after every login and app launch.
    /// </summary>
    [HttpPost("device-token")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceTokenRequest request)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized();

            if (string.IsNullOrWhiteSpace(request.DeviceToken))
            {
                return BadRequest(ApiResponse<bool>.FailureResponse(
                    "رمز الجهاز مطلوب",
                    new List<string> { "DeviceToken لا يمكن أن يكون فارغاً" }));
            }

            var result = await _reminderService.RegisterDeviceTokenAsync(request.DeviceToken, userId.Value);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in RegisterDeviceToken endpoint");
            return StatusCode(500, ApiResponse<bool>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع" }));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET /api/VaccinationReminder/child/{childId}/milestone/{milestoneId}
    // Flutter calls this when opening the تفاصيل الموعد page to populate saved settings
    // ─────────────────────────────────────────────────────────────────────────
    /// <summary>
    /// Get the saved reminder configuration for a specific child and vaccination milestone.
    /// Returns null data if no appointment has been configured yet.
    /// </summary>
    [HttpGet("child/{childId}/milestone/{milestoneId}")]
    [ProducesResponseType(typeof(ApiResponse<ReminderDto?>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ReminderDto?>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetReminder(Guid childId, int milestoneId)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized();

            _logger.LogInformation(
                "Fetching vaccination reminder for child {ChildId}, milestone {MilestoneId}",
                childId, milestoneId);

            var result = await _reminderService.GetReminderAsync(childId, milestoneId, userId.Value);

            if (!result.Success)
            {
                if (result.Message.Contains("غير مصرح"))
                    return StatusCode(403, result);
                return BadRequest(result);
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetReminder endpoint");
            return StatusCode(500, ApiResponse<ReminderDto?>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع" }));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /api/VaccinationReminder/upsert
    // Flutter calls this when parent taps "وضع تذكير" or "إعادة ضبط الموعد"
    // ─────────────────────────────────────────────────────────────────────────
    /// <summary>
    /// Save or reset the vaccination appointment and reminder settings.
    /// Creates a new record if none exists, or updates and resets all reminder flags if it does.
    /// </summary>
    [HttpPost("upsert")]
    [ProducesResponseType(typeof(ApiResponse<ReminderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ReminderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpsertReminder([FromBody] SaveReminderRequest request)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized();

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                return BadRequest(ApiResponse<ReminderDto>.FailureResponse("خطأ في البيانات المدخلة", errors));
            }

            _logger.LogInformation(
                "Upserting vaccination reminder for child {ChildId}, milestone {MilestoneId}",
                request.ChildId, request.MilestoneId);

            var result = await _reminderService.UpsertReminderAsync(request, userId.Value);

            if (!result.Success)
            {
                if (result.Message.Contains("غير مصرح"))
                    return StatusCode(403, result);
                return BadRequest(result);
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpsertReminder endpoint");
            return StatusCode(500, ApiResponse<ReminderDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع" }));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: extract UserId from the JWT claims
    // ─────────────────────────────────────────────────────────────────────────
    private Guid? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                       ?? User.FindFirst("sub")?.Value;

        if (Guid.TryParse(userIdClaim, out var userId))
            return userId;

        return null;
    }
}
