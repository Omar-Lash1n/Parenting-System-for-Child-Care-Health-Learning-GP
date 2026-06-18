namespace Ajial.Domain.Entities;

/// <summary>
/// حجز استشارة طبية من ولي الأمر لدى طبيب — إما كشف داخل العيادة أو جلسة اون لاين.
/// A parent's booking of a doctor's service (in-clinic visit or online remote session).
/// </summary>
public class Booking
{
    public Guid Id { get; set; }

    // ── Who is booking ──
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    /// <summary>
    /// المريض — الطفل المختار. القيمة null تعني أن المريض هو ولي الأمر نفسه (صاحب الحساب).
    /// The patient (selected child). Null means the parent themselves is the patient.
    /// </summary>
    public Guid? ChildId { get; set; }
    public Child? Child { get; set; }

    // ── Doctor & service ──
    public Guid SpecialistId { get; set; }
    public Specialist Specialist { get; set; } = null!;

    public BookingServiceType ServiceType { get; set; }

    public Guid? ClinicId { get; set; }
    public Clinic? Clinic { get; set; }

    public Guid? RemoteConsultationId { get; set; }
    public RemoteConsultation? RemoteConsultation { get; set; }

    // ── Appointment slot (Egypt local time) ──
    /// <summary>تاريخ الموعد (مكوّن التاريخ فقط).</summary>
    public DateTime AppointmentDate { get; set; }

    /// <summary>وقت بداية الجلسة — للجلسات اون لاين فقط. العيادة تعتمد اليوم فقط.</summary>
    public TimeSpan? StartTime { get; set; }

    /// <summary>وقت نهاية الجلسة — للجلسات اون لاين فقط.</summary>
    public TimeSpan? EndTime { get; set; }

    /// <summary>مدة الجلسة بالدقائق — للجلسات اون لاين فقط.</summary>
    public int? DurationMinutes { get; set; }

    /// <summary>السعر وقت الحجز (لقطة) — سعر الكشف للعيادة أو سعر الجلسة اون لاين.</summary>
    public decimal Price { get; set; }

    // ── Patient-provided details ──
    /// <summary>وصف الشكوى الحالية للمريض (اختياري).</summary>
    public string? ComplaintDescription { get; set; }

    /// <summary>مشاركة الملف الطبي للطفل مع الطبيب.</summary>
    public bool ShareMedicalFile { get; set; }

    /// <summary>
    /// رابط الملف الطبي الموحد للطفل (PDF) المُولّد عند الحجز إذا اختار ولي الأمر مشاركته.
    /// null إذا لم تُطلب المشاركة أو كان المريض هو ولي الأمر نفسه (بدون طفل).
    /// </summary>
    public string? MedicalFileUrl { get; set; }

    public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
    public string? RejectionReason { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CancelledAt { get; set; }

    public ICollection<BookingAttachment> Attachments { get; set; } = new List<BookingAttachment>();
    public Payment? Payment { get; set; }
}
