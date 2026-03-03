namespace Ajial.Domain.Entities;

public class Child
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    public string FullName { get; set; } = string.Empty;
    public DateTime BirthDate { get; set; }
    public int Age { get; set; }
    public string Gender { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? ChildLoginId { get; set; }
    public string? PasswordHash { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsActive { get; set; }

    /// <summary>
    /// Last time the child interacted with the app (for online status tracking).
    /// Child is considered "active" if this is within the last 5 minutes.
    /// آخر وقت تفاعل فيه الطفل مع التطبيق
    /// </summary>
    public DateTime? LastActivityAt { get; set; }

    /// <summary>
    /// هل أكمل ولي الأمر استبيان التطعيمات الأساسية؟
    /// Set to true after the parent submits POST /api/Vaccination/survey
    /// </summary>
    public bool HasCompletedVaccinationSurvey { get; set; } = false;

    /// <summary>
    /// هل أكمل ولي الأمر استبيان التطعيمات الإضافية؟ (4-15 سنة)
    /// Set to true after the parent submits POST /api/Vaccination/additional-survey
    /// </summary>
    public bool HasCompletedAdditionalVaccinationSurvey { get; set; } = false;

    // ── الملف الطبي (Medical Profile) ──

    /// <summary>الطول بالسنتيمتر</summary>
    public double? Height { get; set; }

    /// <summary>الوزن بالكيلوجرام</summary>
    public double? Weight { get; set; }

    /// <summary>محيط الدماغ بالسنتيمتر</summary>
    public double? HeadCircumference { get; set; }

    /// <summary>فصيلة الدم (e.g., "A+", "O-", "B+", "AB-")</summary>
    public string? BloodType { get; set; }

    /// <summary>تاريخ طبي - ملاحظات طبية عامة</summary>
    public string? MedicalHistory { get; set; }

    /// <summary>
    /// سجل التطعيمات - Vaccination records for this child
    /// </summary>
    public ICollection<ChildVaccination> Vaccinations { get; set; } = new List<ChildVaccination>();
}