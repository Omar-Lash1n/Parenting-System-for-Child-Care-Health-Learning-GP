using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// السجل الإكلينيكي — جانب الطبيب (المرحلة الخامسة)
// الروشتة الطبية (الأدوية) + التشخيص الطبي — يضيفها الطبيب بعد إنهاء الجلسة،
// وتُحدَّث تلقائياً في الملف الطبي الموحد للطفل (PDF).
// ============================================================

// ── الروشتة الطبية (الأدوية) ──────────────────────────────────────────────

/// <summary>دواء واحد ضمن الروشتة الطبية للحجز.</summary>
public class PrescriptionMedicineDto
{
    public Guid Id { get; set; }

    /// <summary>اسم الدواء (مثل: كونجستال).</summary>
    public string MedicineName { get; set; } = string.Empty;

    /// <summary>الكمية / الجرعة (مثل: نصف قرص يومياً).</summary>
    public string Quantity { get; set; } = string.Empty;

    /// <summary>الموعد / توقيت تناول الدواء (مثل: قبل الغذاء).</summary>
    public string Timing { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>قائمة أدوية الروشتة الطبية لحجز محدد.</summary>
public class PrescriptionListResponse
{
    public Guid BookingId { get; set; }

    /// <summary>هل يُسمح للطبيب بالتعديل على الروشتة الآن (الجلسة منتهية).</summary>
    public bool CanEdit { get; set; }

    public List<PrescriptionMedicineDto> Medicines { get; set; } = new();
}

/// <summary>طلب إضافة دواء جديد للروشتة الطبية.</summary>
public class CreatePrescriptionMedicineRequest
{
    [Required(ErrorMessage = "اسم الدواء مطلوب")]
    [MaxLength(200, ErrorMessage = "اسم الدواء طويل جداً")]
    public string MedicineName { get; set; } = string.Empty;

    [Required(ErrorMessage = "الكمية مطلوبة")]
    [MaxLength(200, ErrorMessage = "الكمية طويلة جداً")]
    public string Quantity { get; set; } = string.Empty;

    [Required(ErrorMessage = "الموعد مطلوب")]
    [MaxLength(200, ErrorMessage = "الموعد طويل جداً")]
    public string Timing { get; set; } = string.Empty;
}

/// <summary>طلب تعديل دواء قائم في الروشتة الطبية.</summary>
public class UpdatePrescriptionMedicineRequest : CreatePrescriptionMedicineRequest { }

// ── التشخيص الطبي ─────────────────────────────────────────────────────────

/// <summary>التشخيص الطبي للمريض في الحجز (واحد لكل حجز).</summary>
public class MedicalDiagnosisDto
{
    public Guid Id { get; set; }

    /// <summary>وصف التشخيص الطبي للمريض.</summary>
    public string Description { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>حالة التشخيص الطبي لحجز محدد (قد لا يوجد تشخيص بعد).</summary>
public class DiagnosisResponse
{
    public Guid BookingId { get; set; }

    /// <summary>هل أضاف الطبيب تشخيصاً بالفعل (لتعطيل زر "اضافة تشخيص").</summary>
    public bool HasDiagnosis { get; set; }

    /// <summary>هل يُسمح للطبيب بالتعديل على التشخيص الآن (الجلسة منتهية).</summary>
    public bool CanEdit { get; set; }

    /// <summary>التشخيص المسجَّل — null إذا لم يُضَف بعد.</summary>
    public MedicalDiagnosisDto? Diagnosis { get; set; }
}

/// <summary>طلب إضافة/تعديل التشخيص الطبي للمريض.</summary>
public class SaveMedicalDiagnosisRequest
{
    [Required(ErrorMessage = "وصف التشخيص مطلوب")]
    [MaxLength(2000, ErrorMessage = "وصف التشخيص طويل جداً")]
    public string Description { get; set; } = string.Empty;
}
