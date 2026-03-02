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

    /// <summary>
    /// Send email verification link to parent's email
    /// إرسال رابط التحقق من البريد الإلكتروني
    /// </summary>
    Task<ApiResponse<SendEmailVerificationResponseDto>> SendEmailVerificationAsync(Guid userId);

    /// <summary>
    /// Verify email using token from verification link
    /// التحقق من البريد الإلكتروني باستخدام الرمز
    /// </summary>
    Task<ApiResponse<VerifyEmailResponseDto>> VerifyEmailAsync(string token);

    /// <summary>
    /// Get all children for the logged-in parent (for "All Children" view)
    /// جلب جميع أطفال ولي الأمر المسجل
    /// </summary>
    Task<ApiResponse<GetParentChildrenResponseDto>> GetParentChildrenAsync(Guid userId);
}