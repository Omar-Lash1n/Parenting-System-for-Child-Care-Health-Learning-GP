namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// ملف تطعيمات الطفل - Child vaccination file response
/// Returns all vaccination data grouped into main + additional sections
/// </summary>
public class GetVaccinationFileResponseDto
{
    public Guid ChildId { get; set; }
    public string ChildName { get; set; } = string.Empty;
    public string? ChildImageUrl { get; set; }

    /// <summary>
    /// عمر الطفل بالشهور
    /// </summary>
    public int AgeMonths { get; set; }

    /// <summary>
    /// الأيام المتبقية بعد الشهور
    /// </summary>
    public int AgeDays { get; set; }

    /// <summary>
    /// العمر مُنسّق بالعربي
    /// </summary>
    public string AgeFormatted { get; set; } = string.Empty;

    /// <summary>
    /// قسم التطعيمات الأساسية (0-18 شهر)
    /// </summary>
    public MainVaccinationSectionDto MainVaccinations { get; set; } = new();

    /// <summary>
    /// قسم التطعيمات الإضافية (4-15 سنة)
    /// </summary>
    public AdditionalVaccinationSectionDto AdditionalVaccinations { get; set; } = new();
}

/// <summary>
/// قسم التطعيمات الأساسية مع العدادات
/// </summary>
public class MainVaccinationSectionDto
{
    /// <summary> الكل </summary>
    public int AllCount { get; set; }

    /// <summary> الحالي </summary>
    public int CurrentCount { get; set; }

    /// <summary> الفائت </summary>
    public int MissedCount { get; set; }

    /// <summary> القادم </summary>
    public int UpcomingCount { get; set; }

    /// <summary> تم </summary>
    public int DoneCount { get; set; }

    public List<VaccinationCardDto> Vaccinations { get; set; } = new();
}

/// <summary>
/// قسم التطعيمات الإضافية مع العدادات
/// </summary>
public class AdditionalVaccinationSectionDto
{
    /// <summary>
    /// هل التطعيمات الإضافية متاحة؟ (الطفل 4 سنوات فأكثر)
    /// false = الطفل أصغر من 4 سنوات، لا تعرض بيانات
    /// </summary>
    public bool IsAvailable { get; set; }

    /// <summary> الكل </summary>
    public int AllCount { get; set; }

    /// <summary> القادم </summary>
    public int UpcomingCount { get; set; }

    /// <summary> تم </summary>
    public int DoneCount { get; set; }

    public List<VaccinationCardDto> Vaccinations { get; set; } = new();
}

/// <summary>
/// بطاقة تطعيم واحدة - Vaccination card for the file view
/// </summary>
public class VaccinationCardDto
{
    public int MilestoneId { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    /// <summary>
    /// وصف اللقاحات بالعربي
    /// </summary>
    public string VaccinesAr { get; set; } = string.Empty;

    /// <summary>
    /// وصف اللقاحات بالإنجليزي
    /// </summary>
    public string VaccinesEn { get; set; } = string.Empty;

    /// <summary>
    /// التصنيف: "حالي" | "فائت" | "قادم" | "تم"
    /// </summary>
    public string Label { get; set; } = string.Empty;

    /// <summary>
    /// Label in English: "Current" | "Missed" | "Upcoming" | "Done"
    /// </summary>
    public string LabelEn { get; set; } = string.Empty;

    /// <summary>
    /// الموعد — تاريخ الولادة + عمر التطعيم بالشهور
    /// </summary>
    public DateTime DueDate { get; set; }

    /// <summary>
    /// الموعد مُنسّق — e.g. "1 مايو 2026"
    /// </summary>
    public string DueDateFormatted { get; set; } = string.Empty;

    /// <summary>
    /// هل تم أخذ التطعيم؟
    /// </summary>
    public bool IsTaken { get; set; }

    /// <summary>
    /// هل القفل مُفعّل؟ (التطعيمات المستقبلية)
    /// </summary>
    public bool IsDisabled { get; set; }

    /// <summary>
    /// عدد أيام التأخير (فقط للتطعيمات الفائتة) — e.g. "فائت منذ 11 يوم"
    /// </summary>
    public int? MissedSinceDays { get; set; }

    /// <summary>
    /// تاريخ الإتمام (فقط للتطعيمات المكتملة)
    /// </summary>
    public DateTime? CompletedDate { get; set; }

    /// <summary>
    /// تاريخ الإتمام مُنسّق — e.g. "تم في 5 مايو 2025"
    /// </summary>
    public string? CompletedDateFormatted { get; set; }
}
