namespace Ajial.Application.DTOs.ChildTask;

public class ChildTaskRecurrenceDto
{
    public bool IsRecurring { get; set; } = false;

    /// <summary>
    /// أيام التكرار - lowercase English day names
    /// Allowed values: "saturday", "friday", "thursday", "wednesday", "tuesday", "monday", "sunday"
    /// </summary>
    public List<string> RepeatDays { get; set; } = new();

    /// <summary>وقت التكرار بصيغة HH:mm — مثال "08:00"</summary>
    public string? RepeatTime { get; set; }
}
