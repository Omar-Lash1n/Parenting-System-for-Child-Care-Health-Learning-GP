using Ajial.Application.DTOs.Clinic;
using Ajial.Application.DTOs.Common;
using Ajial.Domain.Entities;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface IClinicService
{
    // Doctor
    Task<ApiResponse<List<ClinicCardResponse>>> GetDoctorClinicsAsync(Guid userId);
    Task<ApiResponse<ClinicDetailResponse>> GetClinicDetailAsync(Guid clinicId, Guid userId);
    Task<ApiResponse<ClinicStatusChangeResponse>> CreateClinicAsync(Guid userId);
    Task<ApiResponse<ClinicDetailResponse>> UpdateClinicDetailsAsync(Guid clinicId, Guid userId, UpdateClinicDetailsRequest request);
    Task<ApiResponse<ClinicDetailResponse>> UpdateClinicHoursAsync(Guid clinicId, Guid userId, UpdateClinicHoursRequest request);
    Task<ApiResponse<ClinicDocumentInfoResponse>> UploadClinicDocumentAsync(Guid clinicId, Guid userId, ClinicDocumentType documentType, IFormFile file);
    Task<ApiResponse<ClinicStatusChangeResponse>> SubmitClinicAsync(Guid clinicId, Guid userId);
    Task<ApiResponse<ClinicStatusChangeResponse>> CancelClinicAsync(Guid clinicId, Guid userId);
    Task<ApiResponse<ClinicStatusChangeResponse>> StartEditClinicAsync(Guid clinicId, Guid userId);

    // Admin
    Task<ApiResponse<AdminClinicListResponse>> GetClinicsForAdminAsync(int? status, int page, int pageSize);
    Task<ApiResponse<AdminClinicDetailResponse>> GetClinicForAdminAsync(Guid clinicId);
    Task<ApiResponse<ClinicStatusChangeResponse>> ApproveClinicAsync(Guid clinicId, Guid adminUserId);
    Task<ApiResponse<ClinicStatusChangeResponse>> RejectClinicAsync(Guid clinicId, Guid adminUserId, RejectClinicRequest request);
}
