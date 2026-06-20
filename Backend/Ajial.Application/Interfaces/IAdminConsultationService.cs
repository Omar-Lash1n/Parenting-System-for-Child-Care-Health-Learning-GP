using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;

namespace Ajial.Application.Interfaces;

/// <summary>خدمة الأدمن — مراجعة مدفوعات الحجوزات وضبط أرقام الدفع.</summary>
public interface IAdminConsultationService
{
    Task<ApiResponse<AdminPaymentListResponse>> GetPaymentsAsync(int? status, int page, int pageSize);
    Task<ApiResponse<AdminPaymentDetailResponse>> GetPaymentDetailAsync(Guid paymentId);
    Task<ApiResponse<PaymentStatusChangeResponse>> ApprovePaymentAsync(Guid paymentId, Guid adminUserId);
    Task<ApiResponse<PaymentStatusChangeResponse>> RejectPaymentAsync(Guid paymentId, Guid adminUserId, RejectPaymentRequest request);

    Task<ApiResponse<PaymentSettingsResponse>> GetPaymentSettingsAsync();
    Task<ApiResponse<PaymentSettingsResponse>> UpdatePaymentSettingsAsync(Guid adminUserId, UpdatePaymentSettingsRequest request);

    // ── الحجوزات الملغاة (متابعة استرداد المبالغ يدوياً) ──
    /// <summary>قائمة الحجوزات الملغاة مع تفاصيل الاسترداد وصورة إيصال الدفع الأصلي.</summary>
    Task<ApiResponse<AdminCancellationListResponse>> GetCancellationsAsync(int page, int pageSize);

    // ── تقييمات الجلسات ──
    /// <summary>قائمة استبيانات تقييم الجلسات (فلتر اختياري بالطبيب / من أبلغ عن مشكلة).</summary>
    Task<ApiResponse<AdminRatingListResponse>> GetRatingsAsync(Guid? specialistId, bool? hadIssue, int page, int pageSize);

    /// <summary>ملخص تقييمات الأطباء (متوسط + توزيع النجوم لكل طبيب).</summary>
    Task<ApiResponse<AdminDoctorRatingSummaryResponse>> GetDoctorRatingsSummaryAsync();
}
