namespace Ajial.Application.DTOs.Task;

/// <summary>
/// Response for GET /api/Task/parent/{parentId}/done
/// Returns completed tasks flat-sorted by CompletedAt descending.
/// Flutter groups them by CompletedAt.Date for the UI sections.
/// </summary>
public class GetDoneTasksResponseDto
{
    public List<TaskCardDto> Tasks { get; set; } = new();

    /// <summary>
    /// Total number of completed tasks (convenience for badge/count display).
    /// </summary>
    public int TotalCount { get; set; }
}
