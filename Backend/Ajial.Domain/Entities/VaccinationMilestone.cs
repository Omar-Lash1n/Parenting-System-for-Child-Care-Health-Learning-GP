namespace Ajial.Domain.Entities;

/// <summary>
/// جدول التطعيمات الأساسية - Vaccination milestone reference data
/// Seeded with the 7 Egyptian national vaccination milestones
/// </summary>
public class VaccinationMilestone
{
    public int Id { get; set; }

    /// <summary>
    /// اسم التطعيم بالعربي — e.g. "تطعيم الولادة"
    /// </summary>
    public string NameAr { get; set; } = string.Empty;

    /// <summary>
    /// اسم التطعيم بالإنجليزي — e.g. "Birth Vaccination"
    /// </summary>
    public string NameEn { get; set; } = string.Empty;

    /// <summary>
    /// عمر التطعيم بالشهور — 0, 2, 4, 6, 9, 12, 18
    /// </summary>
    public int AgeInMonths { get; set; }

    /// <summary>
    /// اللقاحات بالعربي (مفصولة بفاصلة)
    /// e.g. "كبدي ب رضع, شلل اطفال فموي, طعم بي سي جي"
    /// </summary>
    public string VaccinesAr { get; set; } = string.Empty;

    /// <summary>
    /// اللقاحات بالإنجليزي (مفصولة بفاصلة)
    /// </summary>
    public string VaccinesEn { get; set; } = string.Empty;

    /// <summary>
    /// ترتيب العرض
    /// </summary>
    public int SortOrder { get; set; }

    /// <summary>
    /// حالة التفعيل
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// تصنيف التطعيم: "Main" للتطعيمات الأساسية (0-18 شهر), "Additional" للتطعيمات الإضافية (4-15 سنة)
    /// </summary>
    public string Category { get; set; } = "Main";
}
