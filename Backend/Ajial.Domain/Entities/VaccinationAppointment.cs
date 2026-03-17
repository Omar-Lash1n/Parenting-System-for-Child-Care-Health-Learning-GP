namespace Ajial.Domain.Entities;

/// <summary>
/// Stores the parent-configured appointment and reminder settings for a specific child vaccination.
/// One record per (ChildId + VaccinationMilestoneId) pair — upserted on each save/reset.
/// </summary>
public class VaccinationAppointment
{
    public Guid Id { get; set; }

    // ── Core References ──────────────────────────────────────
    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;

    public int VaccinationMilestoneId { get; set; }
    public VaccinationMilestone VaccinationMilestone { get; set; } = null!;

    // ── Appointment Details ───────────────────────────────────
    /// <summary>اسم الوحدة الصحية / المستشفى</summary>
    public string HealthUnit { get; set; } = string.Empty;

    /// <summary>Appointment date + time combined</summary>
    public DateTime AppointmentDateTime { get; set; }

    // ── Reminder Settings ─────────────────────────────────────
    /// <summary>قبل الموعد بـ يوم</summary>
    public bool NotifyOneDayBefore { get; set; }

    /// <summary>قبل الموعد بـ 3 ساعات</summary>
    public bool NotifyThreeHoursBefore { get; set; }

    /// <summary>ضبط موعد آخر (custom time)</summary>
    public bool CustomReminderEnabled { get; set; }

    /// <summary>The exact DateTime for the custom reminder (nullable)</summary>
    public DateTime? CustomReminderDateTime { get; set; }

    // ── Notification Type ─────────────────────────────────────
    /// <summary>منبّه — local alarm (stored for UI state, handled by Flutter locally)</summary>
    public bool IsAlarmEnabled { get; set; }

    /// <summary>إشعارات — push notification delivered via FCM</summary>
    public bool IsPushEnabled { get; set; }

    // ── Processing Flags (reset to false on each upsert) ──────
    /// <summary>Has the 1-day-before push already been sent?</summary>
    public bool IsProcessedOneDayBefore { get; set; } = false;

    /// <summary>Has the 3-hours-before push already been sent?</summary>
    public bool IsProcessedThreeHoursBefore { get; set; } = false;

    /// <summary>Has the custom-time push already been sent?</summary>
    public bool IsProcessedCustom { get; set; } = false;

    // ── Audit ─────────────────────────────────────────────────
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
