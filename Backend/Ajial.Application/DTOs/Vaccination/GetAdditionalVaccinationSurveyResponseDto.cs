namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// استجابة استبيان التطعيمات الإضافية (4-15 سنة)
/// Additional vaccination survey response — only for children aged 4+ years
/// </summary>
public class GetAdditionalVaccinationSurveyResponseDto
{
    public Guid ChildId { get; set; }
    public string ChildName { get; set; } = string.Empty;
    public string? ChildImageUrl { get; set; }

    /// <summary>
    /// العمر بالسنوات الكاملة — e.g. 7
    /// </summary>
    public int AgeYears { get; set; }

    /// <summary>
    /// العمر مُنسّق بالعربي بدون أرقام — e.g. "سبع سنوات"
    /// </summary>
    public string AgeFormatted { get; set; } = string.Empty;

    /// <summary>
    /// التطعيمات الإضافية الستة مع حالة كل واحد
    /// </summary>
    public List<AdditionalVaccinationMilestoneDto> Milestones { get; set; } = new();
}

/// <summary>
/// بيانات تطعيم إضافي واحد
/// </summary>
public class AdditionalVaccinationMilestoneDto
{
    public int MilestoneId { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    /// <summary>
    /// العمر بالسنوات — 4, 6, 7, 10, 12, 15
    /// </summary>
    public int AgeInYears { get; set; }

    public string VaccinesAr { get; set; } = string.Empty;
    public string VaccinesEn { get; set; } = string.Empty;

    /// <summary>
    /// true = قفل الـ checkbox (عمر الطفل لم يصل بعد)
    /// </summary>
    public bool IsDisabled { get; set; }

    /// <summary>
    /// القيمة الحالية — من DB أو false افتراضياً (لا يوجد auto-select)
    /// </summary>
    public bool IsTaken { get; set; }
}
