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
    Task<ApiResponse<ChildAccountDetailsDto>> GetChildAccountDetailsAsync(Guid childId, Guid parentUserId);
    Task<ApiResponse<ChildAccountDetailsDto>> UpdateChildLoginIdAsync(Guid childId, Guid parentUserId, UpdateChildLoginIdDto request);
    Task<ApiResponse<string>> UpdateChildPasswordAsync(Guid childId, Guid parentUserId, UpdateChildPasswordDto request);
    Task<ApiResponse<ChildAccountDetailsDto>> ToggleChildAccountAsync(Guid childId, Guid parentUserId, ToggleChildAccountDto request);
    Task<ApiResponse<UploadChildImageResponseDto>> DeleteChildProfileImageAsync(Guid childId, Guid parentUserId);
    Task<ApiResponse<ChildAccountDetailsDto>> CreateChildAccountAsync(Guid childId, Guid parentUserId, CreateChildAccountDto request);
}