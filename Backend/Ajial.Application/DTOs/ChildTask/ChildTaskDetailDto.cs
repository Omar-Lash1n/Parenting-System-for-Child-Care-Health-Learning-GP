namespace Ajial.Application.DTOs.ChildTask;

/// <summary>Full task details — returned by GET /{taskId}, POST, PUT</summary>
public class ChildTaskDetailDto
{
    public Guid TaskId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? TaskImageUrl { get; set; }
    public string? RecordingUrl { get; set; }
    public int Stars { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? DueDate { get; set; }

    /// <summary>
    /// Per-child completion status is inside each item of AssignedChildren.
    /// Check AssignedChildren[n].IsCompleted and AssignedChildren[n].CompletedAt
    /// </summary>
    public ChildTaskRecurrenceDto? Recurrence { get; set; }
    public List<AssignedChildDto> AssignedChildren { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
