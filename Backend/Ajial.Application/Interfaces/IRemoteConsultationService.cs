using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.RemoteConsultation;

namespace Ajial.Application.Interfaces;

public interface IRemoteConsultationService
{
    // Doctor
    Task<ApiResponse<List<RemoteConsultationCardResponse>>> GetDoctorConsultationsAsync(Guid userId);
    Task<ApiResponse<RemoteConsultationDetailResponse>> GetConsultationDetailAsync(Guid consultationId, Guid userId);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> CreateConsultationAsync(Guid userId);
    Task<ApiResponse<RemoteConsultationDetailResponse>> UpdateConsultationAsync(Guid consultationId, Guid userId, UpdateRemoteConsultationRequest request);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> SubmitConsultationAsync(Guid consultationId, Guid userId);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> CancelConsultationAsync(Guid consultationId, Guid userId);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> StartEditConsultationAsync(Guid consultationId, Guid userId);

    // Admin
    Task<ApiResponse<AdminRemoteConsultationListResponse>> GetConsultationsForAdminAsync(int? status, int page, int pageSize);
    Task<ApiResponse<AdminRemoteConsultationDetailResponse>> GetConsultationForAdminAsync(Guid consultationId);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> ApproveConsultationAsync(Guid consultationId, Guid adminUserId);
    Task<ApiResponse<RemoteConsultationStatusChangeResponse>> RejectConsultationAsync(Guid consultationId, Guid adminUserId, RejectRemoteConsultationRequest request);
}
