using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;

namespace Ajial.Application.Interfaces;

public interface IPrizeService
{
    Task<ApiResponse<PrizeDetailDto>> CreatePrizeAsync(CreatePrizeRequestDto request, Guid requestingUserId);
    Task<ApiResponse<GetPrizesForChildResponseDto>> GetPrizesForChildAsync(Guid childId, Guid requestingUserId);
    Task<ApiResponse<PrizeDetailDto>> GetPrizeByIdAsync(Guid prizeId, Guid requestingUserId);
    Task<ApiResponse<PrizeDetailDto>> UpdatePrizeAsync(Guid prizeId, UpdatePrizeRequestDto request, Guid requestingUserId);
    Task<ApiResponse<bool>> DeletePrizeAsync(Guid prizeId, Guid requestingUserId);
    Task<ApiResponse<PrizeDetailDto>> DeliverPrizeAsync(Guid prizeId, Guid requestingUserId);
    Task<ApiResponse<GetPrizesForParentResponseDto>> GetPrizesForParentAsync(Guid parentId, Guid requestingUserId);
}
