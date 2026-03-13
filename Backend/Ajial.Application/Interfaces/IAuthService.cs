using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;

namespace Ajlal.Application.Interfaces;

public interface IAuthService
{
    Task<RegisterParentResponse> RegisterParentAsync(RegisterParentRequest request);
    Task<RegisterSpecialistResponse> RegisterSpecialistAsync(RegisterSpecialistRequest request);
    Task<ApiResponse<LoginResponseDto>> LoginParentAsync(LoginRequestDto request);
    Task<ApiResponse<LoginSpecialistResponseDto>> LoginSpecialistAsync(LoginRequestDto request);

    Task<ApiResponse<ForgotPasswordResponseDto>> ForgotPasswordAsync(ForgotPasswordRequestDto request);



    Task<ApiResponse<VerifyOtpResponseDto>> VerifyOtpAsync(VerifyOtpRequestDto request);


    Task<ApiResponse<LoginChildResponseDto>> LoginChildAsync(LoginChildRequestDto request);



    Task<ApiResponse<ResetPasswordResponseDto>> ResetPasswordAsync(ResetPasswordRequestDto request);

    /// <summary>
    /// تسجيل خروج الطفل - Logout child (sets IsActive to false)
    /// </summary>
    Task<ApiResponse<string>> LogoutChildAsync(Guid childId);
}
