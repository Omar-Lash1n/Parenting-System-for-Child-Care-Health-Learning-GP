using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>استشارات طبية — لوحة الأدمن: مراجعة مدفوعات الحجوزات وضبط أرقام الدفع.</summary>
[ApiController]
[AllowAnonymous] // TODO: Restore [Authorize(Roles = "Admin")] (يتبع نفس نمط بقية كنترولرات الأدمن)
[Route("api/admin/consultations")]
public class AdminConsultationController : ControllerBase
{
    private readonly IAdminConsultationService _service;

    public AdminConsultationController(IAdminConsultationService service)
    {
        _service = service;
    }

    /// <summary>قائمة المدفوعات (إيصالات الحجز) مع فلتر اختياري بالحالة.</summary>
    [HttpGet("payments")]
    [ProducesResponseType(typeof(ApiResponse<AdminPaymentListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPayments([FromQuery] int? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => ToActionResult(await _service.GetPaymentsAsync(status, page, pageSize));

    /// <summary>تفاصيل عملية دفع للمراجعة (تتضمن صورة الإيصال).</summary>
    [HttpGet("payments/{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminPaymentDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminPaymentDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPayment(Guid id)
        => ToActionResult(await _service.GetPaymentDetailAsync(id));

    /// <summary>قبول الدفع وتأكيد الحجز.</summary>
    [HttpPost("payments/{id:guid}/approve")]
    [ProducesResponseType(typeof(ApiResponse<PaymentStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaymentStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ApprovePayment(Guid id)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<PaymentStatusChangeResponse>();
        return ToActionResult(await _service.ApprovePaymentAsync(id, adminUserId));
    }

    /// <summary>رفض الدفع مع ذكر السبب.</summary>
    [HttpPost("payments/{id:guid}/reject")]
    [ProducesResponseType(typeof(ApiResponse<PaymentStatusChangeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaymentStatusChangeResponse>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RejectPayment(Guid id, [FromBody] RejectPaymentRequest request)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<PaymentStatusChangeResponse>();
        return ToActionResult(await _service.RejectPaymentAsync(id, adminUserId, request));
    }

    /// <summary>جلب أرقام الدفع الحالية.</summary>
    [HttpGet("payment-settings")]
    [ProducesResponseType(typeof(ApiResponse<PaymentSettingsResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPaymentSettings()
        => ToActionResult(await _service.GetPaymentSettingsAsync());

    /// <summary>تعديل أرقام الدفع (فودافون كاش / انستا باي).</summary>
    [HttpPut("payment-settings")]
    [ProducesResponseType(typeof(ApiResponse<PaymentSettingsResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdatePaymentSettings([FromBody] UpdatePaymentSettingsRequest request)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<PaymentSettingsResponse>();
        return ToActionResult(await _service.UpdatePaymentSettingsAsync(adminUserId, request));
    }

    // ── تقييمات الجلسات ──────────────────────────────────────────────────────────

    /// <summary>قائمة استبيانات تقييم الجلسات (فلتر اختياري: specialistId=طبيب معيّن، hadIssue=true لمن أبلغوا عن مشكلة).</summary>
    [HttpGet("ratings")]
    [ProducesResponseType(typeof(ApiResponse<AdminRatingListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRatings([FromQuery] Guid? specialistId, [FromQuery] bool? hadIssue, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => ToActionResult(await _service.GetRatingsAsync(specialistId, hadIssue, page, pageSize));

    /// <summary>ملخص تقييمات الأطباء (متوسط النجوم + توزيعها لكل طبيب).</summary>
    [HttpGet("ratings/doctors")]
    [ProducesResponseType(typeof(ApiResponse<AdminDoctorRatingSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDoctorRatingsSummary()
        => ToActionResult(await _service.GetDoctorRatingsSummaryAsync());

    // ── Helpers ────────────────────────────────────────────────────────────────

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;
        if (Guid.TryParse(claimValue, out userId))
            return true;
        // Fallback: no auth yet, use empty GUID as placeholder admin
        userId = Guid.Empty;
        return true;
    }

    private ObjectResult UnauthorizedResponse<T>() =>
        StatusCode(StatusCodes.Status401Unauthorized,
            ApiResponse<T>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" }));

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success) return Ok(result);
        if (result.Message.Contains("لم يتم العثور")) return NotFound(result);
        if (result.Message.Contains("لا يمكن")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("حدث خطأ في الخادم")) return StatusCode(StatusCodes.Status500InternalServerError, result);
        return BadRequest(result);
    }
}
