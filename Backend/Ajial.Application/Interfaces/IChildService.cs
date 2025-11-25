using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;

namespace Ajial.Application.Interfaces;

public interface IChildService
{
    Task<ApiResponse<AddChildResponseDto>> AddChildAsync(AddChildRequestDto request, Guid parentId);
    Task<ApiResponse<List<FruitOptionDto>>> GetAvailableFruitsAsync();
    Task<ApiResponse<bool>> CheckChildLoginIdAvailabilityAsync(string childLoginId);
}