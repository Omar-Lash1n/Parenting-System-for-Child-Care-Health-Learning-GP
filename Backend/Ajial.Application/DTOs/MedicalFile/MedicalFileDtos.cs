namespace Ajial.Application.DTOs.MedicalFile;

/// <summary>
/// استجابة توليد الملف الطبي الموحد للطفل — تُعاد لتطبيق ولي الأمر لفتح/تنزيل ملف الـ PDF.
/// </summary>
public class MedicalFileResponse
{
    public Guid ChildId { get; set; }

    /// <summary>اسم الطفل بالكامل.</summary>
    public string ChildName { get; set; } = string.Empty;

    /// <summary>رقم الملف الصحي (ثابت لكل طفل) — مثل AJ-983422.</summary>
    public string FileNumber { get; set; } = string.Empty;

    /// <summary>رابط ملف الـ PDF في Azure Blob Storage (يتضمن مُبطّل تخزين مؤقت).</summary>
    public string FileUrl { get; set; } = string.Empty;

    /// <summary>تاريخ آخر توليد للملف (UTC).</summary>
    public DateTime GeneratedAt { get; set; }
}

// ── النموذج الغني المُمرَّر لمولّد الـ PDF (مستقل عن مكتبة التوليد) ────────────────

/// <summary>
/// كل البيانات اللازمة لرسم الملف الطبي الموحد للطفل في صفحتي الـ PDF.
/// يجمعها MedicalFileService من قاعدة البيانات ويمررها إلى مولّد الـ PDF.
/// </summary>
public class MedicalFileData
{
    // ── ترويسة ──
    public string FileNumber { get; set; } = string.Empty;
    public string LastUpdatedLabel { get; set; } = string.Empty; // "19 يونيو 2026"

    // ── بطاقات الملخص ──
    public string ChildName { get; set; } = string.Empty;
    public string AgeLabel { get; set; } = string.Empty;   // "3 سنوات و 4 أشهر"
    public string BloodType { get; set; } = string.Empty;  // "O+" أو "غير مسجلة"
    public string GeneralGrowthLabel { get; set; } = "طبيعي"; // حالة النمو العامة (ثابتة حالياً)

    // ── بيانات الهوية ──
    public string BirthDateLabel { get; set; } = string.Empty; // "12 يناير 2023"
    public string GuardianName { get; set; } = string.Empty;
    public string EmergencyPhone { get; set; } = string.Empty; // "غير متوفر" حالياً

    // ── مؤشرات النمو (بدون عمود الـ Percentile) ──
    public List<MedicalGrowthRow> Growth { get; set; } = new();

    // ── سجل التطعيمات الأساسية ──
    public List<MedicalVaccineRow> MainVaccines { get; set; } = new();

    // ── التطعيمات الإضافية / الاختيارية ──
    public List<MedicalVaccineRow> OptionalVaccines { get; set; } = new();

    // ── السجل المرضي والتشخيصات السابقة (يُملأ في مرحلة لاحقة) ──
    public List<MedicalConsultationCard> Consultations { get; set; } = new();
}

/// <summary>صف في جدول مؤشرات النمو والقياسات الحيوية.</summary>
public class MedicalGrowthRow
{
    public string Metric { get; set; } = string.Empty; // "الوزن"
    public string Value { get; set; } = string.Empty;  // "14.5 كجم" أو "غير مسجل"
}

/// <summary>صف في جدول التطعيمات (أساسية أو إضافية).</summary>
public class MedicalVaccineRow
{
    public string Name { get; set; } = string.Empty;       // "تطعيم الولادة (الدرن، الكبد الوبائي ب)"
    public string TargetLabel { get; set; } = string.Empty; // "عند الولادة" / "شهران"
    public string DateLabel { get; set; } = string.Empty;   // "13 يناير 2023" أو "—"
    public bool IsTaken { get; set; }
}

/// <summary>
/// بطاقة استشارة سابقة في السجل المرضي — تُعبأ في المرحلة القادمة من ميزة الاستشارات.
/// </summary>
public class MedicalConsultationCard
{
    public string Title { get; set; } = string.Empty;       // "الاستشارة رقم #1402 | التاريخ: ... | طب الأطفال"
    public string Tag { get; set; } = string.Empty;         // "أطفال"
    public string DoctorName { get; set; } = string.Empty;
    public string Diagnosis { get; set; } = string.Empty;
    public List<string> Prescription { get; set; } = new();
    public string? Recommendations { get; set; }
}
