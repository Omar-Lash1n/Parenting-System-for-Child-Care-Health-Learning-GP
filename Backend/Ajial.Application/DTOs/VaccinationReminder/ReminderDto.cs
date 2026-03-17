namespace Ajial.Application.DTOs.VaccinationReminder;

/// <summary>
/// Returned by GET /api/VaccinationReminder/child/{childId}/milestone/{milestoneId}
/// so the Flutter app can populate the تفاصيل الموعد page with previously saved settings.
/// </summary>
public class ReminderDto
{
    public Guid Id { get; set; }
    public Guid ChildId { get; set; }
    public int MilestoneId { get; set; }
    public string HealthUnit { get; set; } = string.Empty;

    /// <summary>yyyy-MM-dd</summary>
    public string AppointmentDate { get; set; } = string.Empty;

    /// <summary>HH:mm</summary>
    public string AppointmentTime { get; set; } = string.Empty;

    public bool NotifyOneDayBefore { get; set; }
    public bool NotifyThreeHoursBefore { get; set; }
    public bool CustomReminderEnabled { get; set; }

    /// <summary>ISO datetime of custom reminder, null if not set.</summary>
    public string? CustomReminderDateTime { get; set; }

    public bool IsAlarmEnabled { get; set; }
    public bool IsPushEnabled { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
