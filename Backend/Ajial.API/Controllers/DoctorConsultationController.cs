using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>
/// استشارات طبية — جانب الطبيب: عرض المواعيد المحجوزة، تفاصيل الحجز، والتحكم في جلسة الكشف اون لاين.
/// </summary>
[ApiController]
[Authorize(Roles = "Doctor,Specialist")]
[Route("api/doctor/consultations")]
public class DoctorConsultationController : ControllerBase
{
    private readonly IDoctorConsultationService _service;

    public DoctorConsultationController(IDoctorConsultationService service)
    {
        _service = service;
    }

    /// <summary>مواعيد يوم محدد للطبيب مع حالة كل موعد (محجوز/متاح). الصيغة: yyyy-MM-dd.</summary>
    [HttpGet("slots")]
    [ProducesResponseType(typeof(ApiResponse<DoctorDaySlotsResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDaySlots([FromQuery] string date)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<DoctorDaySlotsResponse>();
        return ToActionResult(await _service.GetDaySlotsAsync(userId, date));
    }

    /// <summary>الأيام التي تحتوي على حجوزات خلال شهر (للنقطة على التقويم). الصيغة: yyyy-MM.</summary>
    [HttpGet("calendar")]
    [ProducesResponseType(typeof(ApiResponse<DoctorCalendarResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMonthBookings([FromQuery] string month)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<DoctorCalendarResponse>();
        return ToActionResult(await _service.GetMonthBookingsAsync(userId, month));
    }

    /// <summary>تفاصيل حجز كاملة للطبيب: المريض، الشكوى، المرفقات، الملف الطبي، وحالة الجلسة.</summary>
    [HttpGet("bookings/{bookingId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<DoctorBookingDetailResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DoctorBookingDetailResponse>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBookingDetail(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<DoctorBookingDetailResponse>();
        return ToActionResult(await _service.GetBookingDetailAsync(userId, bookingId));
    }

    /// <summary>حالة جلسة الكشف اون لاين للطبيب — للاستعلام المتكرر والعدّ التنازلي.</summary>
    [HttpGet("bookings/{bookingId:guid}/session")]
    [ProducesResponseType(typeof(ApiResponse<DoctorSessionStatusResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSessionStatus(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<DoctorSessionStatusResponse>();
        return ToActionResult(await _service.GetSessionStatusAsync(userId, bookingId));
    }

    /// <summary>
    /// بدء جلسة الكشف اون لاين — يُنشئ رابط Google Meet (متاح فقط بعد حلول موعد الجلسة).
    /// idempotent: الضغط مرتين يُعيد نفس الرابط.
    /// </summary>
    [HttpPost("bookings/{bookingId:guid}/start-session")]
    [ProducesResponseType(typeof(ApiResponse<StartSessionResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> StartSession(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<StartSessionResponse>();
        return ToActionResult(await _service.StartSessionAsync(userId, bookingId));
    }

    /// <summary>
    /// إنهاء الجلسة يدوياً — الحالة تصبح "جلسة مكتملة" لدى الطبيب وولي الأمر.
    /// idempotent: إنهاء جلسة منتهية يُعيد الحالة الحالية دون خطأ.
    /// </summary>
    [HttpPost("bookings/{bookingId:guid}/end-session")]
    [ProducesResponseType(typeof(ApiResponse<DoctorSessionStatusResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> EndSession(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<DoctorSessionStatusResponse>();
        return ToActionResult(await _service.EndSessionAsync(userId, bookingId));
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
        if (result.Message.Contains("لا يمكن")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("انتهى وقت")) return StatusCode(StatusCodes.Status409Conflict, result);
        if (result.Message.Contains("حدث خطأ في الخادم")) return StatusCode(StatusCodes.Status500InternalServerError, result);
        if (result.Message.Contains("تعذّر")) return StatusCode(StatusCodes.Status502BadGateway, result);
        return BadRequest(result);
    }
}
