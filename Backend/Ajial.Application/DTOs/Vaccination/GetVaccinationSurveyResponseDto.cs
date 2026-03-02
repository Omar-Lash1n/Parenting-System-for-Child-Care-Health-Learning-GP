namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// استجابة استبيان التطعيمات - Vaccination survey response DTO
/// </summary>
public class GetVaccinationSurveyResponseDto
{
    public Guid ChildId { get; set; }
    public string ChildName { get; set; } = string.Empty;
    public string? ChildImageUrl { get; set; }

    /// <summary>
    /// عمر الطفل بالشهور — e.g. 4
    /// </summary>
    public int AgeMonths { get; set; }

    /// <summary>
    /// الأيام المتبقية بعد الشهور — e.g. 12
    /// </summary>
    public int AgeDays { get; set; }

    /// <summary>
    /// العمر مُنسّق بالعربي — e.g. "4 شهور و 12 يوم"
    /// </summary>
    public string AgeFormatted { get; set; } = string.Empty;

    /// <summary>
    /// قائمة التطعيمات السبعة مع حالة كل واحد
    /// </summary>
    public List<VaccinationMilestoneDto> Milestones { get; set; } = new();
}

/// <summary>
/// بيانات تطعيم واحد - Single milestone DTO
/// </summary>
public class VaccinationMilestoneDto
{
    public int MilestoneId { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public int AgeInMonths { get; set; }
    public string VaccinesAr { get; set; } = string.Empty;
    public string VaccinesEn { get; set; } = string.Empty;

    /// <summary>
    /// "Past" | "Current" | "Future"
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// true = auto-checked (Rule A & D)
    /// </summary>
    public bool IsAutoSelected { get; set; }

    /// <summary>
    /// true = disabled in UI (Rule C)
    /// </summary>
    public bool IsDisabled { get; set; }

    /// <summary>
    /// Current value: true if child received this vaccination
    /// </summary>
    public bool IsTaken { get; set; }
}
