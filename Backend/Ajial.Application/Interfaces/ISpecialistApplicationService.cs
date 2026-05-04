using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.SpecialistApplication;
using Ajial.Domain.Entities;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface ISpecialistApplicationService
{
    Task<ApiResponse<CurrentApplicationCardResponse>> GetCurrentApplicationAsync(Guid userId);
    Task<ApiResponse<ApplicationDetailsResponse>> GetApplicationDetailsAsync(Guid applicationId, Guid userId);
    Task<ApiResponse<StatusChangeResponse>> SubmitApplicationAsync(Guid applicationId, Guid userId);
    Task<ApiResponse<StatusChangeResponse>> CancelApplicationAsync(Guid applicationId, Guid userId);
    Task<ApiResponse<StatusChangeResponse>> StartEditApplicationAsync(Guid applicationId, Guid userId);
    Task<ApiResponse<IdentityDataDto>> UpdateIdentityDataAsync(Guid applicationId, Guid userId, UpdateIdentityDataRequest request);
    Task<ApiResponse<ProfessionalDataDto>> UpdateProfessionalDataAsync(Guid applicationId, Guid userId, UpdateProfessionalDataRequest request);
    Task<ApiResponse<DocumentInfoDto>> UploadDocumentAsync(Guid applicationId, Guid userId, SpecialistDocumentType documentType, IFormFile file);
    Task<ApiResponse<DocumentInfoDto>> GetDocumentAsync(Guid applicationId, Guid userId, SpecialistDocumentType documentType);
    Task<ApiResponse<StatusChangeResponse>> CreateNewApplicationAsync(Guid userId);
    Task<ApiResponse<IEnumerable<SpecialtyDto>>> GetSpecialtiesAsync();
    Task<ApiResponse<AdminApplicationListResponse>> GetApplicationsForAdminAsync(int? status, int page, int pageSize);
    Task<ApiResponse<AdminApplicationDetailResponse>> GetApplicationForAdminAsync(Guid applicationId);
    Task<ApiResponse<StatusChangeResponse>> ApproveApplicationAsync(Guid applicationId, Guid adminUserId);
    Task<ApiResponse<StatusChangeResponse>> RejectApplicationAsync(Guid applicationId, Guid adminUserId, RejectApplicationRequest request);
}
