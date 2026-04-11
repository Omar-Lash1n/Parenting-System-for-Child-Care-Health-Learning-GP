using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;

namespace Ajial.Application.Interfaces;

public interface ITaskService
{
    Task<ApiResponse<GetTasksResponseDto>> GetTasksAsync(Guid parentId, Guid requestingUserId);
    Task<ApiResponse<TaskCardDto>> GetTaskByIdAsync(Guid taskId, Guid requestingUserId);
    Task<ApiResponse<GetDoneTasksResponseDto>> GetDoneTasksAsync(Guid parentId, Guid requestingUserId);
    Task<ApiResponse<TaskCardDto>> CreateTaskAsync(CreateTaskRequestDto request, Guid requestingUserId);
    Task<ApiResponse<TaskCardDto>> UpdateTaskAsync(Guid taskId, UpdateTaskRequestDto request, Guid requestingUserId);
    Task<ApiResponse<bool>> DeleteTaskAsync(Guid taskId, Guid requestingUserId);
    Task<ApiResponse<TaskCardDto>> ToggleCompleteAsync(Guid taskId, Guid requestingUserId);
}
