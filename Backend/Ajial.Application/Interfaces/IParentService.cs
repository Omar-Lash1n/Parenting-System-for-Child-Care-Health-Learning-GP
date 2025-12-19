using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface IParentService
{
    Task<ApiResponse<List<ParentAnalyticsDto>>> GetAllParentsForAnalyticsAsync();

    Task<ApiResponse<GetParentProfileResponseDto>> GetParentProfileAsync(Guid userId);
    Task<ApiResponse<ChangePasswordResponseDto>> ChangePasswordAsync(Guid userId, ChangePasswordRequestDto request);

    Task<ApiResponse<UpdateParentProfileResponseDto>> UpdateParentProfileAsync(Guid userId, UpdateParentProfileRequestDto request);
    Task<ApiResponse<UploadParentImageResponseDto>> UploadParentProfileImageAsync(
        Guid userId,
        IFormFile image);

    /// <summary>
    /// Delete parent account permanently
    /// حذف حساب ولي الأمر نهائياً
    /// </summary>
    Task<ApiResponse<DeleteParentAccountResponseDto>> DeleteParentAccountAsync(
        Guid userId,
        DeleteParentAccountRequestDto request);
}