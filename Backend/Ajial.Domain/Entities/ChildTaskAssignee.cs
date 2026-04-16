namespace Ajial.Domain.Entities;

/// <summary>
/// جدول الربط بين مهمة الطفل والأطفال المختارين (Many-to-Many)
/// Composite PK: (TaskId, ChildId)
/// Completion is tracked per-child here — not on the ChildTask level
/// </summary>
public class ChildTaskAssignee
{
    public Guid TaskId { get; set; }
    public ChildTask Task { get; set; } = null!;

    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;

    /// <summary>Has the parent marked this task complete for THIS specific child?</summary>
    public bool IsCompleted { get; set; } = false;

    /// <summary>When was it marked complete for this child</summary>
    public DateTime? CompletedAt { get; set; }
}
