namespace Ajial.Domain.Entities;

public class ParentTask
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public Guid? CategoryId { get; set; }
    public TaskCategory? Category { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Color { get; set; }
    public DateTime? DueDate { get; set; }
    public bool IncludeParent { get; set; } = false;
    public bool IsCompleted { get; set; } = false;
    public DateTime? CompletedAt { get; set; }

    /// <summary>
    /// Set to false when user explicitly provides a DueDate — background worker will fire FCM notification.
    /// Set to true when DueDate is defaulted (null from client) or notification already sent.
    /// </summary>
    public bool IsPushSent { get; set; } = false;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<TaskAssignee> Assignees { get; set; } = new List<TaskAssignee>();
}
