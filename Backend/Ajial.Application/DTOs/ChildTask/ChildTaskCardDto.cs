namespace Ajial.Application.DTOs.ChildTask;

/// <summary>Compact card for task list views — used inside GetChildTasksByChild</summary>
public class ChildTaskCardDto
{
    public Guid TaskId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? TaskImageUrl { get; set; }
    public int Stars { get; set; }

    /// <summary>Completion status for the specific child this list was requested for</summary>
    public bool IsCompleted { get; set; }

    /// <summary>When this specific child's task was marked complete</summary>
    public DateTime? CompletedAt { get; set; }

    public DateTime? DueDate { get; set; }

    /// <summary>
    /// Computed recurrence label — e.g. "يتكرر ج، خ"
    /// null if task is not recurring
    /// </summary>
    public string? RecurrenceSummary { get; set; }

    public List<AssignedChildDto> AssignedChildren { get; set; } = new();
}
