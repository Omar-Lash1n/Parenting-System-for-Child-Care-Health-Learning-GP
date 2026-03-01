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

    // Progress bar percentage (0 for now)
    public int ProfileCompletionPercentage { get; set; } = 0;
}
