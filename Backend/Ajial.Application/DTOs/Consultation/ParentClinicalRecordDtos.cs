namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// السجل الإكلينيكي — جانب ولي الأمر (عرض فقط) — المرحلة السادسة
// يعرض ولي الأمر الروشتة الطبية والتشخيص الطبي اللذين سجّلهما الطبيب بعد إنهاء الجلسة.
// كل استجابة "مكتفية بذاتها": تحمل ترويسة البطاقة (الطبيب + المريض + التاريخ) إضافةً للمحتوى،
// لتُرسم بطاقة العرض (الروشتة/التشخيص) دون الحاجة لاستدعاءات أخرى.
// ملاحظة: يعيد الطبيب استخدام DTOs المحتوى نفسها (PrescriptionMedicineDto / MedicalDiagnosisDto).
// ============================================================

/// <summary>ترويسة بطاقة السجل الإكلينيكي لولي الأمر — بيانات الطبيب والمريض والتاريخ المعروضة أعلى البطاقة.</summary>
public abstract class ParentClinicalCardHeader
{
    public Guid BookingId { get; set; }

    /// <summary>اسم الطبيب (مثل: د. محمد ابراهيم).</summary>
    public string DoctorName { get; set; } = string.Empty;

    /// <summary>تخصص الطبيب (مثل: طبيب اسنان).</summary>
    public string Specialization { get; set; } = string.Empty;

    /// <summary>صورة الطبيب الشخصية (اختياري).</summary>
    public string? DoctorPhotoUrl { get; set; }

    /// <summary>اسم المريض (الطفل أو ولي الأمر نفسه).</summary>
    public string PatientName { get; set; } = string.Empty;

    /// <summary>سن المريض بالسنوات — قد يكون null إذا تعذّر حسابه.</summary>
    public int? PatientAge { get; set; }

    /// <summary>تاريخ الموعد بصيغة yyyy-MM-dd (يُعرض في خانة "التاريخ").</summary>
    public string AppointmentDate { get; set; } = string.Empty;

    /// <summary>هل انتهت الجلسة (الحالة مكتملة)؟ قبل ذلك لا يوجد سجل إكلينيكي بعد.</summary>
    public bool IsCompleted { get; set; }
}

/// <summary>الروشتة الطبية كما يراها ولي الأمر — ترويسة البطاقة + قائمة الأدوية.</summary>
public class ParentPrescriptionResponse : ParentClinicalCardHeader
{
    public List<PrescriptionMedicineDto> Medicines { get; set; } = new();
}

/// <summary>التشخيص الطبي كما يراه ولي الأمر — ترويسة البطاقة + نص التشخيص (قد لا يوجد بعد).</summary>
public class ParentDiagnosisResponse : ParentClinicalCardHeader
{
    /// <summary>هل سجّل الطبيب تشخيصاً بالفعل.</summary>
    public bool HasDiagnosis { get; set; }

    /// <summary>التشخيص المسجَّل — null إذا لم يُسجَّل بعد.</summary>
    public MedicalDiagnosisDto? Diagnosis { get; set; }
}
