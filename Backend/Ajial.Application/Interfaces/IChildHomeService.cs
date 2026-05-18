using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;

namespace Ajial.Application.Interfaces;

public interface IChildHomeService
{
    /// <summary>GET /api/ChildHome/tasks — all tasks for the logged-in child</summary>
    Task<ApiResponse<GetChildTasksForChildResponseDto>> GetMyTasksAsync(Guid childId);

    /// <summary>GET /api/ChildHome/tasks/{taskId} — task details with recording URL</summary>
    Task<ApiResponse<ChildTaskDetailDto>> GetMyTaskDetailsAsync(Guid taskId, Guid childId);

    /// <summary>
    /// PATCH /api/ChildHome/tasks/{taskId}/complete — one-way mark as complete.
    /// Idempotent: already-completed tasks return success without side effects.
    /// </summary>
    Task<ApiResponse<ChildTaskDetailDto>> MarkTaskCompleteAsync(Guid taskId, Guid childId);

    /// <summary>GET /api/ChildHome/prizes — all prizes assigned to the logged-in child</summary>
    Task<ApiResponse<GetPrizesForChildResponseDto>> GetMyPrizesAsync(Guid childId);
}
