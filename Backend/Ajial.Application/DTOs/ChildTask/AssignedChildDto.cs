namespace Ajial.Application.DTOs.ChildTask;

public class AssignedChildDto
{
    public Guid ChildId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }

    /// <summary>Has the parent marked this task complete for THIS specific child?</summary>
    public bool IsCompleted { get; set; }

    /// <summary>When it was marked complete for this child (null if not completed)</summary>
    public DateTime? CompletedAt { get; set; }
}
