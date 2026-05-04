using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.SpecialistApplication;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/specialist-applications")]
public class AdminSpecialistApplicationController : ControllerBase
{
    private readonly ISpecialistApplicationService _applicationService;

    public AdminSpecialistApplicationController(ISpecialistApplicationService applicationService)
    {
        _applicationService = applicationService;
    }

    /// <summary>
    /// List specialist applications with optional status filtering.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<AdminApplicationListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetApplications([FromQuery] int? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _applicationService.GetApplicationsForAdminAsync(status, page, pageSize);
        return ToActionResult(result);
    }

    /// <summary>
    /// Get full application details for admin review.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminApplicationDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminApplicationDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetApplication(Guid id)
    {
        var result = await _applicationService.GetApplicationForAdminAsync(id);
        return ToActionResult(result);
    }

    /// <summary>
    /// Approve a pending specialist application.
    /// </summary>
    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ApproveApplication(Guid id)
    {
        if (!TryGetUserId(out var adminUserId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        var result = await _applicationService.ApproveApplicationAsync(id, adminUserId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Reject a pending specialist application with a reason.
    /// </summary>
    [HttpPost("{id:guid}/reject")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RejectApplication(Guid id, [FromBody] RejectApplicationRequest request)
    {
        if (!TryGetUserId(out var adminUserId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(ToModelStateFailure<StatusChangeResponse>());
        }

        var result = await _applicationService.RejectApplicationAsync(id, adminUserId, request);
        return ToActionResult(result);
    }

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;

        return Guid.TryParse(claimValue, out userId);
    }

    private ObjectResult UnauthorizedResponse<T>()
    {
        return StatusCode(StatusCodes.Status401Unauthorized,
            ApiResponse<T>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" }));
    }

    private ApiResponse<T> ToModelStateFailure<T>()
    {
        var errors = ModelState.Values
            .SelectMany(v => v.Errors)
            .Select(e => e.ErrorMessage)
            .ToList();

        return ApiResponse<T>.FailureResponse("خطأ في البيانات المدخلة", errors);
    }

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.Message.Contains("لم يتم العثور"))
        {
            return NotFound(result);
        }

        if (result.Message.Contains("لا يمكن"))
        {
            return StatusCode(StatusCodes.Status409Conflict, result);
        }

        if (result.Message.Contains("حدث خطأ في الخادم"))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        }

        return BadRequest(result);
    }
}
