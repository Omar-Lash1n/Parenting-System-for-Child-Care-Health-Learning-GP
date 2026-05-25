using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Clinic;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Doctor,Specialist")]
[Route("api/doctor/clinics")]
public class DoctorClinicController : ControllerBase
{
    private readonly IClinicService _clinicService;

    public DoctorClinicController(IClinicService clinicService)
    {
        _clinicService = clinicService;
    }

    /// <summary>List the authenticated doctor's clinics.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<ClinicCardResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyClinics()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<ClinicCardResponse>>();
        var result = await _clinicService.GetDoctorClinicsAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>Get full detail of a specific clinic.</summary>
    [HttpGet("{clinicId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ClinicDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ClinicDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetClinicDetail(Guid clinicId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicDetailResponse>();
        var result = await _clinicService.GetClinicDetailAsync(clinicId, userId);
        return ToActionResult(result);
    }

    /// <summary>Create a new clinic draft.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateClinic()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        var result = await _clinicService.CreateClinicAsync(userId);
        return ToActionResult(result);
    }

    /// <summary>Update Step 1 — clinic details (name, governorate, district, address, phone). Sends only changed fields.</summary>
    [HttpPut("{clinicId:guid}/details")]
    [ProducesResponseType(typeof(ApiResponse<ClinicDetailResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateDetails(Guid clinicId, [FromBody] UpdateClinicDetailsRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicDetailResponse>();
        var result = await _clinicService.UpdateClinicDetailsAsync(clinicId, userId, request);
        return ToActionResult(result);
    }

    /// <summary>Update Step 2 — working hours and pricing. Sends only changed fields.</summary>
    [HttpPut("{clinicId:guid}/hours")]
    [ProducesResponseType(typeof(ApiResponse<ClinicDetailResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateHours(Guid clinicId, [FromBody] UpdateClinicHoursRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicDetailResponse>();
        var result = await _clinicService.UpdateClinicHoursAsync(clinicId, userId, request);
        return ToActionResult(result);
    }

    /// <summary>Upload or replace a single clinic certification document (Step 3).</summary>
    [HttpPut("{clinicId:guid}/documents/{documentType}")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ClinicDocumentInfoResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UploadDocument(
        Guid clinicId,
        ClinicDocumentType documentType,
        [FromForm] UploadClinicDocumentRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicDocumentInfoResponse>();
        var result = await _clinicService.UploadClinicDocumentAsync(clinicId, userId, documentType, request.File);
        return ToActionResult(result);
    }

    /// <summary>Submit the clinic draft for admin review.</summary>
    [HttpPost("{clinicId:guid}/submit")]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SubmitClinic(Guid clinicId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        var result = await _clinicService.SubmitClinicAsync(clinicId, userId);
        return ToActionResult(result);
    }

    /// <summary>Cancel a clinic request (Draft, Pending, or Rejected).</summary>
    [HttpPost("{clinicId:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CancelClinic(Guid clinicId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        var result = await _clinicService.CancelClinicAsync(clinicId, userId);
        return ToActionResult(result);
    }

    /// <summary>Pull a Pending clinic back to Draft for editing.</summary>
    [HttpPost("{clinicId:guid}/start-edit")]
    [ProducesResponseType(typeof(ApiResponse<ClinicStatusChangeResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> StartEditClinic(Guid clinicId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ClinicStatusChangeResponse>();
        var result = await _clinicService.StartEditClinicAsync(clinicId, userId);
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
