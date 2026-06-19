using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

/// <summary>خدمة الاستشارات الطبية لجانب ولي الأمر — اكتشاف الأطباء والحجز والدفع.</summary>
public interface IConsultationService
{
    // ── الاكتشاف ──
    Task<ApiResponse<List<AvailableDoctorResponse>>> GetAvailableDoctorsAsync(string? search, string? specialization);
    Task<ApiResponse<List<SpecialtyChipResponse>>> GetSpecialtyChipsAsync();
    Task<ApiResponse<DoctorProfileResponse>> GetDoctorProfileAsync(Guid specialistId);
    Task<ApiResponse<BookingInfoResponse>> GetBookingInfoAsync(Guid specialistId);
    Task<ApiResponse<DaySlotsResponse>> GetSlotsAsync(Guid specialistId, string serviceType, string date);
    Task<ApiResponse<NearestSlotResponse>> GetNearestSlotAsync(Guid specialistId, string serviceType);

    // ── الحجز والدفع ──
    Task<ApiResponse<List<PatientResponse>>> GetPatientsAsync(Guid userId);
    Task<ApiResponse<PaymentMethodsResponse>> GetPaymentMethodsAsync();
    Task<ApiResponse<BookingSummaryResponse>> CreateBookingAsync(Guid userId, CreateBookingRequest request);
    Task<ApiResponse<List<AttachmentDto>>> AddAttachmentAsync(Guid userId, Guid bookingId, IFormFile file);
    Task<ApiResponse<List<AttachmentDto>>> DeleteAttachmentAsync(Guid userId, Guid bookingId, Guid attachmentId);
    Task<ApiResponse<BookingSummaryResponse>> SubmitPaymentAsync(Guid userId, Guid bookingId, SubmitPaymentRequest request);

    // ── حجوزاتي والمعاملات المالية ──
    Task<ApiResponse<List<BookingListItemResponse>>> GetMyBookingsAsync(Guid userId, int? status);
    Task<ApiResponse<BookingDetailResponse>> GetBookingDetailAsync(Guid userId, Guid bookingId);
    Task<ApiResponse<BookingDetailResponse>> CancelBookingAsync(Guid userId, Guid bookingId);
    Task<ApiResponse<List<ParentPaymentListItemResponse>>> GetMyPaymentsAsync(Guid userId);

    // ── جلسة الكشف اون لاين (Google Meet) ──
    /// <summary>حالة جلسة الكشف اون لاين لولي الأمر (العدّ التنازلي + إتاحة الانضمام).</summary>
    Task<ApiResponse<SessionStatusResponse>> GetSessionStatusAsync(Guid userId, Guid bookingId);
}
