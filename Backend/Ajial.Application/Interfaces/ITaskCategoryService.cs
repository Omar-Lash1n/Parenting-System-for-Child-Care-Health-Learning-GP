using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;
using Ajial.Application.DTOs.TaskCategory;

namespace Ajial.Application.Interfaces;

public interface ITaskCategoryService
{
    Task<ApiResponse<GetCategoriesResponseDto>> GetCategoriesAsync(Guid parentId, Guid requestingUserId);
    Task<ApiResponse<TaskCategoryDto>> CreateCategoryAsync(CreateCategoryRequestDto request, Guid requestingUserId);
    Task<ApiResponse<TaskCategoryDto>> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequestDto request, Guid requestingUserId);
    Task<ApiResponse<bool>> DeleteCategoryAsync(Guid categoryId, Guid requestingUserId);
}
