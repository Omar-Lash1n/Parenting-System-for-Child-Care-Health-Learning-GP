namespace Ajial.Domain.Entities;

/// <summary>
/// مهمة طفل - A task assigned by a parent to one or more children
/// Separate from ParentTask (مهامي) to keep concerns clean
/// Completion is NOT tracked here — it lives in ChildTaskAssignee per child
/// </summary>
public class ChildTask
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    public string Title { get; set; } = string.Empty;

    /// <summary>صورة المهمة - Optional task illustration image URL</summary>
    public string? TaskImageUrl { get; set; }

    /// <summary>رابط التسجيل الصوتي في Azure (child-tasks-recording container)</summary>
    public string? RecordingUrl { get; set; }

    /// <summary>عدد النجوم / النقاط المكتسبة عند إتمام المهمة</summary>
    public int Stars { get; set; } = 0;

    /// <summary>تاريخ البدء (اختياري)</summary>
    public DateTime? StartDate { get; set; }

    /// <summary>تاريخ الاستحقاق (اختياري)</summary>
    public DateTime? DueDate { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public ICollection<ChildTaskAssignee> Assignees { get; set; } = new List<ChildTaskAssignee>();
    public ChildTaskRecurrence? Recurrence { get; set; }
}
