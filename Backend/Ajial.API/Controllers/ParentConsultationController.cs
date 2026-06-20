using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>استشارات طبية — جانب ولي الأمر: اكتشاف الأطباء والحجز والدفع.</summary>
[ApiController]
[Authorize(Roles = "Parent")]
[Route("api/parent/consultations")]
public class ParentConsultationController : ControllerBase
{
    private readonly IConsultationService _service;

    public ParentConsultationController(IConsultationService service)
    {
        _service = service;
    }

    // ── الاكتشاف ───────────────────────────────────────────────────────────────

    /// <summary>قائمة الأطباء المتاحين (لديهم عيادة و/أو كشف عن بعد مقبول).</summary>
    [HttpGet("doctors")]
    [ProducesResponseType(typeof(ApiResponse<List<AvailableDoctorResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDoctors([FromQuery] string? search, [FromQuery] string? specialty)
        => ToActionResult(await _service.GetAvailableDoctorsAsync(search, specialty));

    /// <summary>تخصصات الأطباء المتاحين لشرائح الفلتر.</summary>
    [HttpGet("specialties")]
    [ProducesResponseType(typeof(ApiResponse<List<SpecialtyChipResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSpecialties()
        => ToActionResult(await _service.GetSpecialtyChipsAsync());

    /// <summary>ملف الطبيب الشخصي.</summary>
    [HttpGet("doctors/{specialistId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<DoctorProfileResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDoctorProfile(Guid specialistId)
        => ToActionResult(await _service.GetDoctorProfileAsync(specialistId));

    /// <summary>بيانات تهيئة صفحة الحجز (حالة كل خدمة وتفاصيلها).</summary>
    [HttpGet("doctors/{specialistId:guid}/booking-info")]
    [ProducesResponseType(typeof(ApiResponse<BookingInfoResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBookingInfo(Guid specialistId)
        => ToActionResult(await _service.GetBookingInfoAsync(specialistId));

    /// <summary>مواعيد يوم محدد لخدمة محددة (serviceType=clinic|remote, date=yyyy-MM-dd).</summary>
    [HttpGet("doctors/{specialistId:guid}/slots")]
    [ProducesResponseType(typeof(ApiResponse<DaySlotsResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSlots(Guid specialistId, [FromQuery] string serviceType, [FromQuery] string date)
        => ToActionResult(await _service.GetSlotsAsync(specialistId, serviceType, date));

    /// <summary>أقرب موعد متاح (زر "احجز اقرب موعد").</summary>
    [HttpGet("doctors/{specialistId:guid}/nearest-slot")]
    [ProducesResponseType(typeof(ApiResponse<NearestSlotResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNearestSlot(Guid specialistId, [FromQuery] string serviceType)
        => ToActionResult(await _service.GetNearestSlotAsync(specialistId, serviceType));

    // ── الحجز والدفع ───────────────────────────────────────────────────────────

    /// <summary>قائمة المرضى (ولي الأمر + أطفاله المفعّلون).</summary>
    [HttpGet("patients")]
    [ProducesResponseType(typeof(ApiResponse<List<PatientResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPatients()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<PatientResponse>>();
        return ToActionResult(await _service.GetPatientsAsync(userId));
    }

    /// <summary>أرقام المحافظ المعروضة في شاشة الدفع.</summary>
    [HttpGet("payment-methods")]
    [ProducesResponseType(typeof(ApiResponse<PaymentMethodsResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPaymentMethods()
        => ToActionResult(await _service.GetPaymentMethodsAsync());

    /// <summary>إنشاء حجز (تفاصيل الحجز → الانتقال للدفع).</summary>
    [HttpPost("bookings")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<BookingSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateBooking([FromForm] CreateBookingRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<BookingSummaryResponse>();
        return ToActionResult(await _service.CreateBookingAsync(userId, request));
    }

    /// <summary>رفع صورة مرفق إضافية للحجز.</summary>
    [HttpPost("bookings/{bookingId:guid}/attachments")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<List<AttachmentDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> AddAttachment(Guid bookingId, [FromForm] AddAttachmentRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<AttachmentDto>>();
        return ToActionResult(await _service.AddAttachmentAsync(userId, bookingId, request.File));
    }

    /// <summary>حذف مرفق من الحجز.</summary>
    [HttpDelete("bookings/{bookingId:guid}/attachments/{attachmentId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<List<AttachmentDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteAttachment(Guid bookingId, Guid attachmentId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<AttachmentDto>>();
        return ToActionResult(await _service.DeleteAttachmentAsync(userId, bookingId, attachmentId));
    }

    /// <summary>رفع إيصال الدفع وتأكيد الحجز.</summary>
    [HttpPost("bookings/{bookingId:guid}/payment")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<BookingSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SubmitPayment(Guid bookingId, [FromForm] SubmitPaymentRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<BookingSummaryResponse>();
        return ToActionResult(await _service.SubmitPaymentAsync(userId, bookingId, request));
    }

    // ── حجوزاتي والمعاملات المالية ─────────────────────────────────────────────

    /// <summary>قائمة حجوزات ولي الأمر (?status= اختياري).</summary>
    [HttpGet("bookings")]
    [ProducesResponseType(typeof(ApiResponse<List<BookingListItemResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBookings([FromQuery] int? status)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<BookingListItemResponse>>();
        return ToActionResult(await _service.GetMyBookingsAsync(userId, status));
    }

    /// <summary>تفاصيل حجز.</summary>
    [HttpGet("bookings/{bookingId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<BookingDetailResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBookingDetail(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<BookingDetailResponse>();
        return ToActionResult(await _service.GetBookingDetailAsync(userId, bookingId));
    }

    /// <summary>إلغاء حجز.</summary>
    [HttpPost("bookings/{bookingId:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<BookingDetailResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CancelBooking(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<BookingDetailResponse>();
        return ToActionResult(await _service.CancelBookingAsync(userId, bookingId));
    }

    /// <summary>حالة جلسة الكشف اون لاين (عدّ تنازلي + إتاحة زر "بدء الجلسة" والرابط). يُستعلم عنها دورياً.</summary>
    [HttpGet("bookings/{bookingId:guid}/session")]
    [ProducesResponseType(typeof(ApiResponse<SessionStatusResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSessionStatus(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<SessionStatusResponse>();
        return ToActionResult(await _service.GetSessionStatusAsync(userId, bookingId));
    }

    // ── السجل الإكلينيكي (عرض الروشتة والتشخيص بعد إنهاء الجلسة) ─────────────────

    /// <summary>الروشتة الطبية التي سجّلها الطبيب لهذا الحجز (بطاقة عرض مكتفية بذاتها).</summary>
    [HttpGet("bookings/{bookingId:guid}/prescription")]
    [ProducesResponseType(typeof(ApiResponse<ParentPrescriptionResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ParentPrescriptionResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPrescription(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ParentPrescriptionResponse>();
        return ToActionResult(await _service.GetPrescriptionAsync(userId, bookingId));
    }

    /// <summary>التشخيص الطبي الذي سجّله الطبيب لهذا الحجز (بطاقة عرض مكتفية بذاتها).</summary>
    [HttpGet("bookings/{bookingId:guid}/diagnosis")]
    [ProducesResponseType(typeof(ApiResponse<ParentDiagnosisResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ParentDiagnosisResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDiagnosis(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ParentDiagnosisResponse>();
        return ToActionResult(await _service.GetDiagnosisAsync(userId, bookingId));
    }

    /// <summary>المعاملات المالية لولي الأمر.</summary>
    [HttpGet("payments")]
    [ProducesResponseType(typeof(ApiResponse<List<ParentPaymentListItemResponse>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyPayments()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<ParentPaymentListItemResponse>>();
        return ToActionResult(await _service.GetMyPaymentsAsync(userId));
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

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
        if (result.Message.Contains("تم حجز هذا الموعد")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("لا يمكن")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("حدث خطأ في الخادم")) return StatusCode(StatusCodes.Status500InternalServerError, result);
        return BadRequest(result);
    }
}
