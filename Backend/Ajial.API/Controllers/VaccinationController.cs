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

    /// <summary>
    /// صفحة ترحيب التطعيمات - Get vaccination welcome page for a child
    /// </summary>
    /// <remarks>
    /// Returns the child's name and profile image for the vaccination welcome screen.
    /// 
    /// This is the first page the parent sees when entering the vaccination section
    /// for a specific child. It displays:
    /// - **FullName**: اسم الطفل الكامل
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
            // Get parent's user ID from JWT token
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
                {
                    return NotFound(result);
                }

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
}
