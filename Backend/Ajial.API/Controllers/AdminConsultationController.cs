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

    // ── الحجوزات الملغاة ─────────────────────────────────────────────────────────

    /// <summary>قائمة الحجوزات الملغاة لمتابعة استرداد المبالغ يدوياً (تتضمن صورة إيصال الدفع الأصلي وطريقة الدفع والمبلغ المسترد).</summary>
    [HttpGet("cancellations")]
    [ProducesResponseType(typeof(ApiResponse<AdminCancellationListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCancellations([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => ToActionResult(await _service.GetCancellationsAsync(page, pageSize));

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

    // ── بلاغات المشاكل (الإبلاغ عن مشكلة) ───────────────────────────────────────

    /// <summary>قائمة بلاغات المشاكل (فلتر اختياري: specialistId=طبيب، status=الحالة، category=نوع المشكلة).</summary>
    [HttpGet("problem-reports")]
    [ProducesResponseType(typeof(ApiResponse<AdminProblemReportListResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProblemReports([FromQuery] Guid? specialistId, [FromQuery] int? status, [FromQuery] int? category, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => ToActionResult(await _service.GetProblemReportsAsync(specialistId, status, category, page, pageSize));

    /// <summary>تفاصيل بلاغ مشكلة.</summary>
    [HttpGet("problem-reports/{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminProblemReportItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminProblemReportItemDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProblemReport(Guid id)
        => ToActionResult(await _service.GetProblemReportDetailAsync(id));

    /// <summary>تحديث حالة بلاغ مشكلة (جديد / قيد المراجعة / تم الحل) مع ملاحظة اختيارية.</summary>
    [HttpPatch("problem-reports/{id:guid}/status")]
    [ProducesResponseType(typeof(ApiResponse<AdminProblemReportItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AdminProblemReportItemDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProblemReportStatus(Guid id, [FromBody] UpdateProblemReportStatusRequest request)
    {
        if (!TryGetUserId(out var adminUserId)) return UnauthorizedResponse<AdminProblemReportItemDto>();
        return ToActionResult(await _service.UpdateProblemReportStatusAsync(id, adminUserId, request));
    }

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
