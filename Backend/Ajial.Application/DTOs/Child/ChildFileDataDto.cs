namespace Ajial.Application.DTOs.Child;

public class ChildFileDataDto
{
    // ── الملف الشخصي (Personal Profile) ──
    public Guid ChildId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public int AgeYears { get; set; }
    public int AgeMonths { get; set; }
    public int AgeDays { get; set; }
    public string Gender { get; set; } = string.Empty;

    // ── الملف الطبي (Medical Profile) ──
    // null means the field has not been filled yet (display default label)
    public string? Height { get; set; }
    public string? Weight { get; set; }
    public string? HeadCircumference { get; set; }
    public string? BloodType { get; set; }
    public string? MedicalHistory { get; set; }

    // ── Progress ──
    public int ProfileCompletionPercentage { get; set; }

    // ── حساب الطفل (Child Account Status) ──
    public bool IsEligibleForAccount { get; set; }    // true if age >= 4
    public bool HasAccount { get; set; }              // true if ChildLoginId exists
    public string AccountStatusMessage { get; set; } = string.Empty;
    public string AccountAction { get; set; } = string.Empty; // "not_eligible" | "create_account" | "view_account"
}
