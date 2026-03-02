using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Vaccination;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VaccinationController : ControllerBase
{
    private readonly IVaccinationService _vaccinationService;
    private readonly ILogger<VaccinationController> _logger;

    public VaccinationController(
        IVaccinationService vaccinationService,
        ILogger<VaccinationController> logger)
    {
        _vaccinationService = vaccinationService;
        _logger = logger;
    }

    // ────────────────────────────────────────────
    // 1. Welcome Page
    // ────────────────────────────────────────────

    /// <summary>
    /// صفحة ترحيب التطعيمات - Get vaccination welcome page for a child
    /// </summary>
    /// <remarks>
    /// Returns the child's first name and profile image for the vaccination welcome screen.
    /// 
    /// This is the first page the parent sees when entering the vaccination section
    /// for a specific child. It displays:
    /// - **FullName**: الاسم الأول للطفل
    /// - **ProfileImageUrl**: رابط صورة الطفل (nullable - use default avatar if null)
    /// 
    /// Requires authentication — the child must belong to the logged-in parent.
    /// </remarks>
    /// <param name="childId">معرّف الطفل - Child's unique identifier</param>
    [HttpGet("welcome/{childId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<VaccinationWelcomeResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VaccinationWelcomeResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<VaccinationWelcomeResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<VaccinationWelcomeResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetVaccinationWelcome(Guid childId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized vaccination welcome access attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول للوصول إلى سجل التطعيمات" }
                ));
            }

            _logger.LogInformation(
                "Vaccination welcome page requested by parent {UserId} for child {ChildId}",
                userId, childId);

            var result = await _vaccinationService.GetVaccinationWelcomeAsync(childId, userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to get vaccination welcome for child {ChildId}. Errors: {Errors}",
                    childId, string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("غير موجود")))
                    return NotFound(result);

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Vaccination welcome page returned successfully for child {ChildId}: {ChildName}",
                childId, result.Data?.FullName);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetVaccinationWelcome endpoint for child {ChildId}", childId);
            return StatusCode(500, ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب بيانات التطعيمات" }
            ));
        }
    }

    // ────────────────────────────────────────────
    // 2. Get Vaccination Survey
    // ────────────────────────────────────────────

    /// <summary>
    /// استبيان التطعيمات - Get vaccination survey for a child
    /// </summary>
    /// <remarks>
    /// Returns the 7 vaccination milestones with dynamic status based on the child's age.
    /// 
    /// **Age is returned as months + days** (e.g., AgeMonths=4, AgeDays=12, AgeFormatted="4 شهور و 12 يوم")
    /// 
    /// **Business Rules:**
    /// - **Rule A (Past)**: VaccineAge &lt; ChildAge → Auto-Selected ✅ (user can uncheck)
    /// - **Rule B (Current)**: VaccineAge == ChildAge → Unselected (user can select)
    /// - **Rule C (Future)**: VaccineAge &gt; ChildAge → Disabled 🔒
    /// - **Rule D (18+)**: Child is 18+ months → All enabled &amp; auto-selected
    /// 
    /// Requires authentication — the child must belong to the logged-in parent.
    /// </remarks>
    /// <param name="childId">معرّف الطفل - Child's unique identifier</param>
    [HttpGet("survey/{childId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetVaccinationSurveyResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<GetVaccinationSurveyResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<GetVaccinationSurveyResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<GetVaccinationSurveyResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetVaccinationSurvey(Guid childId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized vaccination survey access attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<GetVaccinationSurveyResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول للوصول إلى استبيان التطعيمات" }
                ));
            }

            _logger.LogInformation(
                "Vaccination survey requested by parent {UserId} for child {ChildId}",
                userId, childId);

            var result = await _vaccinationService.GetVaccinationSurveyAsync(childId, userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to get vaccination survey for child {ChildId}. Errors: {Errors}",
                    childId, string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("غير موجود")))
                    return NotFound(result);

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Vaccination survey returned for child {ChildId} (age: {AgeMonths}m {AgeDays}d). Milestones: {Count}",
                childId, result.Data?.AgeMonths, result.Data?.AgeDays, result.Data?.Milestones?.Count);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetVaccinationSurvey endpoint for child {ChildId}", childId);
            return StatusCode(500, ApiResponse<GetVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب استبيان التطعيمات" }
            ));
        }
    }

    // ────────────────────────────────────────────
    // 3. Submit Vaccination Survey
    // ────────────────────────────────────────────

    /// <summary>
    /// تقديم استبيان التطعيمات - Submit vaccination survey results
    /// </summary>
    /// <remarks>
    /// Saves the parent's vaccination selections for a specific child.
    /// 
    /// **Rules:**
    /// - Cannot submit a **future** (disabled) milestone as taken
    /// - Existing records are **updated** (upsert), not duplicated
    /// - Records are persisted for use in the "Kid Vaccination File" endpoint
    /// 
    /// Requires authentication — the child must belong to the logged-in parent.
    /// </remarks>
    /// <param name="request">قائمة اختيارات التطعيمات - Vaccination selections</param>
    [HttpPost("survey")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> SubmitVaccinationSurvey([FromBody] SubmitVaccinationSurveyRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized vaccination survey submit attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لتسجيل التطعيمات" }
                ));
            }

            _logger.LogInformation(
                "Vaccination survey submission by parent {UserId} for child {ChildId}. Selections: {Count}",
                userId, request.ChildId, request.Selections?.Count ?? 0);

            var result = await _vaccinationService.SubmitVaccinationSurveyAsync(request, userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to submit vaccination survey for child {ChildId}. Errors: {Errors}",
                    request.ChildId, string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("غير موجود")))
                    return NotFound(result);

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Vaccination survey submitted for child {ChildId}. Taken: {Taken}/{Total}",
                request.ChildId, result.Data?.TakenCount, result.Data?.TotalMilestones);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in SubmitVaccinationSurvey endpoint for child {ChildId}", request.ChildId);
            return StatusCode(500, ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء حفظ استبيان التطعيمات" }
            ));
        }
    }

    // ────────────────────────────────────────────
    // 4. Get Additional Vaccination Survey
    // ────────────────────────────────────────────

    /// <summary>
    /// التطعيمات الإضافية - Get additional vaccination survey (4-15 year milestones)
    /// </summary>
    /// <remarks>
    /// Returns 6 school-age vaccination milestones (4–15 years).
    ///
    /// **Only available for children aged 4 years or older** (ageMonths &gt;= 48).
    /// If the child is younger, returns a 400 error — Flutter should not show this page.
    ///
    /// **Key differences from the main survey:**
    /// - No auto-selection — all checkboxes start unchecked
    /// - No "Past/Current/Future" — only `isDisabled: true/false`
    /// - Selection is fully optional (parent can choose any or none)
    ///
    /// Requires authentication — the child must belong to the logged-in parent.
    /// </remarks>
    /// <param name="childId">معرّف الطفل - Child's unique identifier</param>
    [HttpGet("additional-survey/{childId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetAdditionalVaccinationSurvey(Guid childId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized additional vaccination survey access attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<GetAdditionalVaccinationSurveyResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول للوصول إلى التطعيمات الإضافية" }
                ));
            }

            _logger.LogInformation(
                "Additional vaccination survey requested by parent {UserId} for child {ChildId}",
                userId, childId);

            var result = await _vaccinationService.GetAdditionalVaccinationSurveyAsync(childId, userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to get additional vaccination survey for child {ChildId}. Errors: {Errors}",
                    childId, string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("غير موجود")))
                    return NotFound(result);

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Additional vaccination survey returned for child {ChildId} (age: {AgeYears} years). Milestones: {Count}",
                childId, result.Data?.AgeYears, result.Data?.Milestones?.Count);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAdditionalVaccinationSurvey endpoint for child {ChildId}", childId);
            return StatusCode(500, ApiResponse<GetAdditionalVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب التطعيمات الإضافية" }
            ));
        }
    }

    // ────────────────────────────────────────────
    // 5. Submit Additional Vaccination Survey
    // ────────────────────────────────────────────

    /// <summary>
    /// تقديم التطعيمات الإضافية - Submit additional vaccination survey results
    /// </summary>
    /// <remarks>
    /// Saves the parent's additional vaccination selections for a child aged 4+ years.
    ///
    /// **Rules:**
    /// - Cannot mark a future milestone (child too young) as taken
    /// - Existing records are updated (upsert) — safe to call multiple times
    ///
    /// Requires authentication — the child must belong to the logged-in parent.
    /// </remarks>
    /// <param name="request">قائمة اختيارات التطعيمات الإضافية</param>
    [HttpPost("additional-survey")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<SubmitVaccinationSurveyResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> SubmitAdditionalVaccinationSurvey([FromBody] SubmitVaccinationSurveyRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized additional vaccination survey submit attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لتسجيل التطعيمات الإضافية" }
                ));
            }

            _logger.LogInformation(
                "Additional vaccination survey submission by parent {UserId} for child {ChildId}. Selections: {Count}",
                userId, request.ChildId, request.Selections?.Count ?? 0);

            var result = await _vaccinationService.SubmitAdditionalVaccinationSurveyAsync(request, userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to submit additional vaccination survey for child {ChildId}. Errors: {Errors}",
                    request.ChildId, string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("غير موجود")))
                    return NotFound(result);

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Additional vaccination survey submitted for child {ChildId}. Taken: {Taken}/{Total}",
                request.ChildId, result.Data?.TakenCount, result.Data?.TotalMilestones);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in SubmitAdditionalVaccinationSurvey endpoint for child {ChildId}", request.ChildId);
            return StatusCode(500, ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء حفظ التطعيمات الإضافية" }
            ));
        }
    }
}
