using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;

namespace Ajial.Application.Interfaces;

/// <summary>
/// خدمة الاستشارات الطبية لجانب الطبيب.
/// المرحلة الثالثة: بدء جلسة الكشف اون لاين.
/// المرحلة الرابعة: عرض المواعيد المحجوزة، تفاصيل الحجز، حالة الجلسة، وإنهاء الجلسة.
/// </summary>
public interface IDoctorConsultationService
{
    /// <summary>مواعيد يوم محدد للطبيب مع حالة كل موعد (محجوز/متاح) ومعرّف الحجز للمحجوز.</summary>
    Task<ApiResponse<DoctorDaySlotsResponse>> GetDaySlotsAsync(Guid userId, string date);

    /// <summary>الأيام التي تحتوي على حجوزات خلال شهر محدد — لإظهار النقطة على التقويم.</summary>
    Task<ApiResponse<DoctorCalendarResponse>> GetMonthBookingsAsync(Guid userId, string month);

    /// <summary>تفاصيل حجز كاملة للطبيب: بيانات المريض، الشكوى، المرفقات، الملف الطبي، وحالة الجلسة.</summary>
    Task<ApiResponse<DoctorBookingDetailResponse>> GetBookingDetailAsync(Guid userId, Guid bookingId);

    /// <summary>حالة جلسة الكشف اون لاين للطبيب — خفيفة، مخصّصة للاستعلام المتكرر والعدّ التنازلي.</summary>
    Task<ApiResponse<DoctorSessionStatusResponse>> GetSessionStatusAsync(Guid userId, Guid bookingId);

    /// <summary>
    /// يبدأ الطبيب جلسة الكشف اون لاين: يُنشئ رابط Google Meet ويُرجعه.
    /// idempotent — الضغط مرتين يُعيد نفس الرابط دون إنشاء اجتماع جديد.
    /// </summary>
    Task<ApiResponse<StartSessionResponse>> StartSessionAsync(Guid userId, Guid bookingId);

    /// <summary>
    /// ينهي الطبيب الجلسة يدوياً: الحالة → مكتملة (جلسة مكتملة) لدى الطبيب وولي الأمر.
    /// idempotent — إنهاء جلسة منتهية يُعيد الحالة الحالية دون خطأ.
    /// </summary>
    Task<ApiResponse<DoctorSessionStatusResponse>> EndSessionAsync(Guid userId, Guid bookingId);
}
