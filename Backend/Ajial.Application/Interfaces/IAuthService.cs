using Ajial.Application.DTOs.Auth;

namespace Ajlal.Application.Interfaces;

public interface IAuthService
{
    Task<RegisterParentResponse> RegisterParentAsync(RegisterParentRequest request);
}