namespace Ajial.Domain.Entities;

/// <summary>
/// تكرار مهمة الطفل - One-to-one with ChildTask
/// Stores recurrence rule as a simple flat row (no complex scheduling tables)
/// RepeatDays is stored as comma-separated English lowercase day names:
/// e.g. "saturday,thursday" or "friday,monday,wednesday"
/// </summary>
public class ChildTaskRecurrence
{
    public Guid Id { get; set; }

    public Guid TaskId { get; set; }
    public ChildTask Task { get; set; } = null!;

    /// <summary>هل المهمة متكررة؟</summary>
    public bool IsRecurring { get; set; } = false;

    /// <summary>
    /// أيام التكرار مخزنة كنص مفصول بفاصلة
    /// e.g. "saturday,thursday"
    /// </summary>
    public string? RepeatDays { get; set; }

    /// <summary>
    /// وقت التكرار بصيغة HH:mm
    /// e.g. "08:00"
    /// </summary>
    public string? RepeatTime { get; set; }
}
