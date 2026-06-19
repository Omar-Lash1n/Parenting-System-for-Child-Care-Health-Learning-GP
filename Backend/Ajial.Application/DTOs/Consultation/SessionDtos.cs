namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// جلسة الكشف اون لاين (Google Meet) — المرحلة الثالثة
// ============================================================

/// <summary>
/// حالة جلسة الكشف اون لاين لولي الأمر — تُستخدم لتفعيل/تعطيل زر "بدء الجلسة"،
/// عرض العدّ التنازلي، وإتاحة رابط الانضمام بعد بدء الطبيب للجلسة.
/// مصمّمة للاستعلام المتكرر (polling) فهي خفيفة.
/// </summary>
public class SessionStatusResponse
{
    public Guid BookingId { get; set; }

    public string ServiceType { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;

    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty; // yyyy-MM-dd
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }

    /// <summary>التوقيت الحالي للخادم بتوقيت مصر — مرجع للعميل لحساب العدّ التنازلي بدقة.</summary>
    public DateTime ServerTimeEgypt { get; set; }

    /// <summary>عدد الثواني المتبقية حتى موعد بداية الجلسة (سالب إذا حلّ الموعد بالفعل).</summary>
    public long SecondsUntilStart { get; set; }

    /// <summary>هل بدأ الطبيب الجلسة فعلياً (تم إنشاء رابط Meet).</summary>
    public bool DoctorStarted { get; set; }

    /// <summary>هل يمكن لولي الأمر الانضمام الآن (الطبيب بدأ + يوجد رابط).</summary>
    public bool CanJoin { get; set; }

    /// <summary>رابط الانضمام لـ Google Meet — يُملأ فقط عندما CanJoin = true.</summary>
    public string? JoinUrl { get; set; }
}

/// <summary>نتيجة بدء الطبيب للجلسة — يحتوي رابط Meet لانضمام الطبيب.</summary>
public class StartSessionResponse
{
    public Guid BookingId { get; set; }
    public string JoinUrl { get; set; } = string.Empty;
    public DateTime SessionStartedAt { get; set; }

    public string AppointmentDate { get; set; } = string.Empty;
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public string PatientName { get; set; } = string.Empty;
}
