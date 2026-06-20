using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// إنشاء الحجز + الدفع + قوائم حجوزات/مدفوعات ولي الأمر
// ============================================================

/// <summary>طلب إنشاء حجز (شاشة تفاصيل الحجز → الانتقال الى الدفع). multipart/form-data.</summary>
public class CreateBookingRequest
{
    public Guid SpecialistId { get; set; }

    /// <summary>1 = كشف داخل العيادة، 2 = جلسة اون لاين.</summary>
    public int ServiceType { get; set; }

    /// <summary>معرّف الطفل المريض — اتركه فارغاً إذا كان المريض هو ولي الأمر نفسه.</summary>
    public Guid? ChildId { get; set; }

    /// <summary>تاريخ الموعد بصيغة yyyy-MM-dd.</summary>
    public string SlotDate { get; set; } = string.Empty;

    /// <summary>وقت بداية الجلسة بصيغة HH:mm — مطلوب للجلسات اون لاين، يُتجاهل للعيادة.</summary>
    public string? StartTime { get; set; }

    public string? ComplaintDescription { get; set; }

    public bool ShareMedicalFile { get; set; }

    /// <summary>صور التحاليل أو الأشعة (اختياري).</summary>
    public List<IFormFile>? Attachments { get; set; }
}

/// <summary>ملخص الحجز بعد الإنشاء — للانتقال لشاشة الدفع.</summary>
public class BookingSummaryResponse
{
    public Guid BookingId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;

    public string ServiceType { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;

    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty; // yyyy-MM-dd
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int? DurationMinutes { get; set; }

    public decimal Amount { get; set; }
    public string PatientName { get; set; } = string.Empty;
}

/// <summary>طلب رفع إيصال الدفع (شاشة الدفع → تأكيد الحجز وإرسال الإيصال). multipart/form-data.</summary>
public class SubmitPaymentRequest
{
    /// <summary>1 = فودافون كاش، 2 = انستا باي.</summary>
    public int Method { get; set; }

    public IFormFile Receipt { get; set; } = null!;
}

/// <summary>رفع صورة مرفق إضافية للحجز. multipart/form-data.</summary>
public class AddAttachmentRequest
{
    public IFormFile File { get; set; } = null!;
}

/// <summary>أرقام المحافظ المعروضة في شاشة الدفع (يضبطها الأدمن).</summary>
public class PaymentMethodsResponse
{
    public string VodafoneCashNumber { get; set; } = string.Empty;
    public string InstaPayNumber { get; set; } = string.Empty;
}

public class AttachmentDto
{
    public Guid Id { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
}

/// <summary>عنصر في قائمة حجوزات ولي الأمر (حجوزاتي).</summary>
public class BookingListItemResponse
{
    public Guid BookingId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;

    public string ServiceType { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;

    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty;
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int? DurationMinutes { get; set; }
    public decimal Price { get; set; }

    public string PatientName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool CanCancel { get; set; }
}

/// <summary>تفاصيل حجز كاملة.</summary>
public class BookingDetailResponse
{
    public Guid BookingId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }

    public string ServiceType { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;

    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty;
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int? DurationMinutes { get; set; }
    public decimal Price { get; set; }

    public string PatientName { get; set; } = string.Empty;
    public Guid? ChildId { get; set; }
    public string? ComplaintDescription { get; set; }
    public bool ShareMedicalFile { get; set; }

    /// <summary>رابط الملف الطبي الموحد للطفل (PDF) إذا اختار ولي الأمر مشاركته عند الحجز.</summary>
    public string? MedicalFileUrl { get; set; }
    public List<AttachmentDto> Attachments { get; set; } = new();

    // الدفع المرتبط (إن وُجد)
    public string? PaymentStatus { get; set; }
    public string? PaymentStatusAr { get; set; }
    public string? PaymentMethod { get; set; }
    public string? ReceiptImageUrl { get; set; }

    public DateTime CreatedAt { get; set; }
    public bool CanCancel { get; set; }

    // ── تقييم الجلسة (المرحلة الثامنة) ──
    /// <summary>هل تم تقييم هذه الجلسة من قبل.</summary>
    public bool HasRated { get; set; }

    /// <summary>هل يمكن تقييم الجلسة الان (مكتملة ولم تُقيَّم بعد) — يتحكم في إظهار زر "قيّم الجلسة واحصل على 250".</summary>
    public bool CanRate { get; set; }
}

/// <summary>عنصر في قائمة المعاملات المالية لولي الأمر.</summary>
public class ParentPaymentListItemResponse
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string MethodAr { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? ReceiptImageUrl { get; set; }
    public string AppointmentDate { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
