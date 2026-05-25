using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.RemoteConsultation;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Doctor,Specialist")]
[Route("api/doctor/remote-consultations")]
public class DoctorRemoteConsultationController : ControllerBase
{
    private readonly IRemoteConsultationService _service;

    public DoctorRemoteConsultationController(IRemoteConsultationService service)
    {
        _service = service;
    }

    /// <summary>List the authenticated doctor's remote consultations.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<RemoteConsultationCardResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyConsultations()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<RemoteConsultationCardResponse>>();
        var result = await _service.GetDoctorConsultationsAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>Get full detail of a specific remote consultation.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDetail(Guid id)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationDetailResponse>();
        var result = await _service.GetConsultationDetailAsync(id, userId);
        return ToActionResult(result);
    }

    /// <summary>Create a new remote consultation draft.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateConsultation()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        var result = await _service.CreateConsultationAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>Update remote consultation fields. Send only the fields that changed.</summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationDetailResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateRemoteConsultationRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationDetailResponse>();
        var result = await _service.UpdateConsultationAsync(id, userId, request);
        return ToActionResult(result);
    }

    /// <summary>Submit the consultation draft for admin review.</summary>
    [HttpPost("{id:guid}/submit")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Submit(Guid id)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        var result = await _service.SubmitConsultationAsync(id, userId);
        return ToActionResult(result);
    }

    /// <summary>Cancel a remote consultation request.</summary>
    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Cancel(Guid id)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        var result = await _service.CancelConsultationAsync(id, userId);
        return ToActionResult(result);
    }

    /// <summary>Pull a Pending consultation back to Draft for editing.</summary>
    [HttpPost("{id:guid}/start-edit")]
    [ProducesResponseType(typeof(ApiResponse<RemoteConsultationStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> StartEdit(Guid id)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<RemoteConsultationStatusChangeResponse>();
        var result = await _service.StartEditConsultationAsync(id, userId);
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

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success) return Ok(result);
        if (result.Message.Contains("لم يتم العثور")) return NotFound(result);
        if (result.Message.Contains("غير مصرح")) return StatusCode(StatusCodes.Status403Forbidden, result);
        if (result.Message.Contains("لا يمكن")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("حدث خطأ في الخادم")) return StatusCode(StatusCodes.Status500InternalServerError, result);
        return BadRequest(result);
    }
}
