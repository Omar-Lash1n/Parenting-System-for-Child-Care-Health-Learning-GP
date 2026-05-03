using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Home;

namespace Ajial.Application.Interfaces;

public interface IParentHomeService
{
    Task<ApiResponse<GetCurrentVaccinationsResponseDto>> GetCurrentVaccinationsAsync(Guid parentUserId);
    Task<ApiResponse<GetUpcomingTasksResponseDto>> GetUpcomingTasksAsync(Guid parentUserId, int limit = 5);
}
