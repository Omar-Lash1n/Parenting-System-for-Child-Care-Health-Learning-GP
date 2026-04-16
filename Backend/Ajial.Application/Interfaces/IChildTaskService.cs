using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;

namespace Ajial.Application.Interfaces;

public interface IChildTaskService
{
    /// <summary>GET /api/ChildTask/parent/{parentId}/children</summary>
    Task<ApiResponse<GetChildrenForTasksResponseDto>> GetChildrenForTasksAsync(Guid parentId, Guid requestingUserId);

    /// <summary>POST /api/ChildTask — multipart/form-data, uploads image + recording internally</summary>
    Task<ApiResponse<ChildTaskDetailDto>> CreateChildTaskAsync(CreateChildTaskRequestDto request, Guid requestingUserId);

    /// <summary>GET /api/ChildTask/child/{childId} — all tasks for a specific child</summary>
    Task<ApiResponse<GetChildTasksForChildResponseDto>> GetChildTasksByChildAsync(Guid childId, Guid requestingUserId);

    /// <summary>
    /// GET /api/ChildTask/{taskId}/child/{childId}
    /// Returns full task details. childId is required to verify the child is assigned to this task.
    /// Completion status inside assignedChildren reflects per-child state.
    /// </summary>
    Task<ApiResponse<ChildTaskDetailDto>> GetChildTaskByIdAsync(Guid taskId, Guid childId, Guid requestingUserId);

    /// <summary>
    /// PUT /api/ChildTask/{taskId}/child/{childId} — multipart/form-data, partial update
    /// childId verifies the child is still assigned before allowing edits.
    /// Edits apply to the shared task record (all assignees see the change).
    /// </summary>
    Task<ApiResponse<ChildTaskDetailDto>> UpdateChildTaskAsync(Guid taskId, Guid childId, UpdateChildTaskRequestDto request, Guid requestingUserId);

    /// <summary>
    /// DELETE /api/ChildTask/{taskId}/child/{childId}
    /// Removes the specific child from the task's assignees.
    /// If this was the last assignee → deletes the entire task + blobs from Azure.
    /// </summary>
    Task<ApiResponse<bool>> RemoveChildFromTaskAsync(Guid taskId, Guid childId, Guid requestingUserId);

    /// <summary>
    /// PATCH /api/ChildTask/{taskId}/child/{childId}/complete
    /// Toggles the completion status for ONE specific child only.
    /// </summary>
    Task<ApiResponse<ChildTaskDetailDto>> ToggleChildTaskCompleteAsync(Guid taskId, Guid childId, Guid requestingUserId);

    /// <summary>GET /api/ChildTask/parent/{parentId}/summary</summary>
    Task<ApiResponse<ChildTaskSummaryDto>> GetChildTaskSummaryAsync(Guid parentId, Guid requestingUserId);
}
