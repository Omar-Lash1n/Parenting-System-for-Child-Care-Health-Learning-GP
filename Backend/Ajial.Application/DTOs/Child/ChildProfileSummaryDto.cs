namespace Ajial.Application.DTOs.Child;

public class ChildProfileSummaryDto
{
    public Guid ChildId { get; set; }

    // First Name
    public string FirstName { get; set; } = string.Empty;

    // Exact Age parts
    public int AgeYears { get; set; }
    public int AgeMonths { get; set; }
    public int AgeDays { get; set; }

    // Child Image URL
    public string? ProfileImageUrl { get; set; }

    // Progress bar percentage
    public int ProfileCompletionPercentage { get; set; } = 0;

    // ── حساب الطفل (Child Account Status) ──
    public bool IsEligibleForAccount { get; set; }    // true if age >= 4
    public bool HasAccount { get; set; }              // true if ChildLoginId exists
    public string AccountStatusMessage { get; set; } = string.Empty;
    public string AccountAction { get; set; } = string.Empty; // "not_eligible" | "create_account" | "view_account"
}
