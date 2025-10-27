using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;

namespace Ajlal.Application.Interfaces;

public interface IAuthService
{
    Task<RegisterParentResponse> RegisterParentAsync(RegisterParentRequest request);
    Task<ApiResponse<LoginResponseDto>> LoginParentAsync(LoginRequestDto request);
}
