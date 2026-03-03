using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface IChildService
{
    Task<ApiResponse<AddChildResponseDto>> AddChildAsync(AddChildRequestDto request, Guid parentId);
    Task<ApiResponse<List<FruitOptionDto>>> GetAvailableFruitsAsync();
    Task<ApiResponse<bool>> CheckChildLoginIdAvailabilityAsync(string childLoginId);
    Task<ApiResponse<ChildProfileSummaryDto>> GetChildProfileSummaryAsync(Guid childId, Guid parentId);
    Task<ApiResponse<ChildFileDataDto>> GetChildFileDataAsync(Guid childId, Guid parentUserId);
    Task<ApiResponse<UpdateChildMedicalDataResponseDto>> UpdateChildMedicalDataAsync(Guid childId, Guid parentUserId, UpdateChildMedicalDataDto request);
    Task<ApiResponse<DeleteChildResponseDto>> DeleteChildAsync(Guid childId, Guid parentUserId);
    Task<ApiResponse<UploadChildImageResponseDto>> UploadChildProfileImageAsync(Guid childId, Guid parentUserId, IFormFile image);
}