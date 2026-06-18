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
}
