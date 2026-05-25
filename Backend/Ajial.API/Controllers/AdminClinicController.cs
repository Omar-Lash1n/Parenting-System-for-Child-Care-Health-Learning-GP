using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Clinic;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/clinics")]
public class AdminClinicController : ControllerBase
{
    private readonly IClinicService _clinicService;

    public AdminClinicController(IClinicService clinicService)
    {
        _clinicService = clinicService;
    }

    /// <summary>List all clinics with optional status filter.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<AdminClinicListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetClinics([FromQuery] int? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _clinicService.GetClinicsForAdminAsync(status, page, pageSize);
        return ToActionResult(result);
    }

    /// <summary>Get full clinic detail for admin review.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminClinicDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminClinicDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetClinic(Guid id)
    {
        var result = await _clinicService.GetClinicForAdminAsync(id);
        return ToActionResult(result);
    }

    /// <summary>Approve a pending clinic.</summary>
    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ApproveClinic(Guid id)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        var result = await _clinicService.ApproveClinicAsync(id, adminUserId);
        return ToActionResult(result);
    }

    /// <summary>Reject a pending clinic with a reason.</summary>
    [HttpPost("{id:guid}/reject")]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RejectClinic(Guid id, [FromBody] RejectClinicRequest request)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        if (!ModelState.IsValid) return BadRequest(ToModelStateFailure<ClinicStatusChangeResponse>());
        var result = await _clinicService.RejectClinicAsync(id, adminUserId, request);
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
