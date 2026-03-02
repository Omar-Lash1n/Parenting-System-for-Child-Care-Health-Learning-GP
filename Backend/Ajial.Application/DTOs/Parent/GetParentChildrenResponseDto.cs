namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response DTO for GET api/parents/children
/// يحتوي على قائمة أطفال ولي الأمر
/// </summary>
public class GetParentChildrenResponseDto
{
    /// <summary>
    /// Total number of children
    /// العدد الإجمالي للأطفال
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// List of children summaries
    /// قائمة ملخصات الأطفال
    /// </summary>
    public List<ChildSummaryDto> Children { get; set; } = new();
}

/// <summary>
/// Child summary for the "All Children" view
/// ملخص بيانات الطفل لعرض "جميع الأطفال"
/// </summary>
public class ChildSummaryDto
{
    /// <summary>
    /// Child unique ID
    /// </summary>
    public Guid ChildId { get; set; }

    /// <summary>
    /// Child's full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Child's profile photo URL (nullable - use default avatar if null)
    /// </summary>
    public string? PhotoUrl { get; set; }

    /// <summary>
    /// Calculated age based on BirthDate
    /// العمر المحسوب من تاريخ الميلاد
    /// </summary>
    public int Age { get; set; }

    /// <summary>
    /// Whether the child is currently active/online (green dot in UI).
    /// Calculated from LastActivityAt — true if within last 5 minutes.
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Whether the child has their own login credentials
    /// </summary>
    public bool HasAccount { get; set; }

    /// <summary>
    /// Number of prizes/achievements (placeholder - defaults to 0)
    /// عدد الأوسمة والإنجازات (مؤقتاً = 0)
    /// </summary>
    public int PrizeCount { get; set; }
}
