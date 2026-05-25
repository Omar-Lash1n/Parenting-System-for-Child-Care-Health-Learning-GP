using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.RemoteConsultation;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/remote-consultations")]
public class AdminRemoteConsultationController : ControllerBase
{
    private readonly IRemoteConsultationService _service;

    public AdminRemoteConsultationController(IRemoteConsultationService service)
    {
        _service = service;
    }

    /// <summary>List all remote consultations with optional status filter.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<AdminRemoteConsultationListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetConsultations([FromQuery] int? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _service.GetConsultationsForAdminAsync(status, page, pageSize);
        return ToActionResult(result);
    }

    /// <summary>Get full detail of a remote consultation for admin review.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminRemoteConsultationDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminRemoteConsultationDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetConsultation(Guid id)
    {
        var result = await _service.GetConsultationForAdminAsync(id);
        return ToActionResult(result);
    }

    /// <summary>Approve a pending remote consultation.</summary>
    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Approve(Guid id)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        var result = await _service.ApproveConsultationAsync(id, adminUserId);
        return ToActionResult(result);
    }

    /// <summary>Reject a pending remote consultation with a reason.</summary>
    [HttpPost("{id:guid}/reject")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Reject(Guid id, [FromBody] RejectRemoteConsultationRequest request)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        if (!ModelState.IsValid) return BadRequest(ToModelStateFailure<RemoteConsultationStatusChangeResponse>());
        var result = await _service.RejectConsultationAsync(id, adminUserId, request);
        return ToActionResult(result);
    }

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;
        return Guid.TryParse(claimValue, out userId);
    }

    private ObjectResult UnauthorizedResponse<T>() =>
        StatusCode(StatusCodes.Status401Unauthorized,
            ApiResponse<T>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" }));

    private ApiResponse<T> ToModelStateFailure<T>()
    {
        var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
        return ApiResponse<T>.FailureResponse("خطأ في البيانات المدخلة", errors);
    }

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success) return Ok(result);
        if (result.Message.Contains("لم يتم العثور")) return NotFound(result);
        if (result.Message.Contains("لا يمكن")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("حدث خطأ في الخادم")) return StatusCode(StatusCodes.Status500InternalServerError, result);
        return BadRequest(result);
    }
}
