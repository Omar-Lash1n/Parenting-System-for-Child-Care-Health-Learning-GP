namespace Ajial.Application.DTOs.VaccinationReminder;

/// <summary>
/// Sent by the Flutter app when saving or resetting the reminder page (تفاصيل الموعد).
/// </summary>
public class SaveReminderRequest
{
    /// <summary>ID of the child this appointment belongs to.</summary>
    public Guid ChildId { get; set; }

    /// <summary>ID of the vaccination milestone (e.g., 2-month, 4-month).</summary>
    public int MilestoneId { get; set; }

    /// <summary>اسم الوحدة الصحية / المستشفى</summary>
    public string HealthUnit { get; set; } = string.Empty;

    /// <summary>Appointment date — format: yyyy-MM-dd</summary>
    public string AppointmentDate { get; set; } = string.Empty;

    /// <summary>Appointment time — format: HH:mm (24-hour)</summary>
    public string AppointmentTime { get; set; } = string.Empty;

    // ── Reminder toggles ──────────────────────────────────────
    public bool NotifyOneDayBefore { get; set; }
    public bool NotifyThreeHoursBefore { get; set; }
    public bool CustomReminderEnabled { get; set; }

    /// <summary>
    /// Optional. Required when CustomReminderEnabled = true.
    /// The custom reminder date-time in full ISO format: yyyy-MM-ddTHH:mm
    /// </summary>
    public string? CustomReminderDateTime { get; set; }

    // ── Notification type ─────────────────────────────────────
    /// <summary>منبّه — local alarm toggle state (stored for UI, triggered locally by Flutter)</summary>
    public bool IsAlarmEnabled { get; set; }

    /// <summary>إشعارات — push notification via Firebase (handled by backend)</summary>
    public bool IsPushEnabled { get; set; }
}
