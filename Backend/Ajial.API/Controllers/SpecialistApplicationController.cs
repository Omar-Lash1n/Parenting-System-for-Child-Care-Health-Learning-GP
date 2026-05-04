using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.SpecialistApplication;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Doctor,Specialist")]
[Route("api/specialist/application")]
public class SpecialistApplicationController : ControllerBase
{
    private readonly ISpecialistApplicationService _applicationService;

    public SpecialistApplicationController(ISpecialistApplicationService applicationService)
    {
        _applicationService = applicationService;
    }

    /// <summary>
    /// Get the specialist's current application card for the dashboard.
    /// </summary>
    [HttpGet("current")]
    [ProducesResponseType(typeof(ApiResponse<CurrentApplicationCardResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<CurrentApplicationCardResponse>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<CurrentApplicationCardResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentApplication()
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<CurrentApplicationCardResponse>();
        }

        var result = await _applicationService.GetCurrentApplicationAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Get full application details for the authenticated specialist.
    /// </summary>
    [HttpGet("{applicationId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ApplicationDetailsResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ApplicationDetailsResponse>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<ApplicationDetailsResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetApplicationDetails(Guid applicationId)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<ApplicationDetailsResponse>();
        }

        var result = await _applicationService.GetApplicationDetailsAsync(applicationId, userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Submit a draft application for review.
    /// </summary>
    [HttpPost("{applicationId:guid}/submit")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> SubmitApplication(Guid applicationId)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        var result = await _applicationService.SubmitApplicationAsync(applicationId, userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Cancel a pending or draft application.
    /// </summary>
    [HttpPost("{applicationId:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CancelApplication(Guid applicationId)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        var result = await _applicationService.CancelApplicationAsync(applicationId, userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Stop review and move a pending application back to draft.
    /// </summary>
    [HttpPost("{applicationId:guid}/start-edit")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> StartEditApplication(Guid applicationId)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        var result = await _applicationService.StartEditApplicationAsync(applicationId, userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Update identity documents.
    /// </summary>
    [HttpPut("{applicationId:guid}/identity")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<IdentityDataDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateIdentityData(Guid applicationId, [FromForm] UpdateIdentityDataRequest request)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<IdentityDataDto>();
        }

        var result = await _applicationService.UpdateIdentityDataAsync(applicationId, userId, request);
        return ToActionResult(result);
    }

    /// <summary>
    /// Update professional practice data.
    /// </summary>
    [HttpPut("{applicationId:guid}/professional")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ProfessionalDataDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateProfessionalData(Guid applicationId, [FromForm] UpdateProfessionalDataRequest request)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<ProfessionalDataDto>();
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(ToModelStateFailure<ProfessionalDataDto>());
        }

        var result = await _applicationService.UpdateProfessionalDataAsync(applicationId, userId, request);
        return ToActionResult(result);
    }

    /// <summary>
    /// Upload or replace a single application document.
    /// </summary>
    [HttpPut("{applicationId:guid}/documents/{documentType}")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<DocumentInfoDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UploadDocument(
        Guid applicationId,
        SpecialistDocumentType documentType,
        [FromForm] UploadDocumentRequest request)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<DocumentInfoDto>();
        }

        if (!ModelState.IsValid)
        {
            return BadRequest(ToModelStateFailure<DocumentInfoDto>());
        }

        var result = await _applicationService.UploadDocumentAsync(applicationId, userId, documentType, request.File);
        return ToActionResult(result);
    }

    /// <summary>
    /// Get a single document URL.
    /// </summary>
    [HttpGet("{applicationId:guid}/documents/{documentType}")]
    [ProducesResponseType(typeof(ApiResponse<DocumentInfoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DocumentInfoDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDocument(Guid applicationId, SpecialistDocumentType documentType)
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<DocumentInfoDto>();
        }

        var result = await _applicationService.GetDocumentAsync(applicationId, userId, documentType);
        return ToActionResult(result);
    }

    /// <summary>
    /// Create a new draft from a cancelled or rejected application.
    /// </summary>
    [HttpPost("new")]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<StatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateNewApplication()
    {
        if (!TryGetUserId(out var userId))
        {
            return UnauthorizedResponse<StatusChangeResponse>();
        }

        var result = await _applicationService.CreateNewApplicationAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>
    /// Get available specialties for the dropdown.
    /// </summary>
    [HttpGet("/api/specialist/specialties")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<SpecialtyDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSpecialties()
    {
        var result = await _applicationService.GetSpecialtiesAsync();
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

        if (result.Message.Contains("غير مصرح - هذا الطلب لا يخصك"))
        {
            return StatusCode(StatusCodes.Status403Forbidden, result);
        }

        if (result.Message.Contains("لم يتم العثور") || result.Message.Contains("لم يتم رفع المستند"))
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
