namespace Ajial.Domain.Entities;

/// <summary>
/// بلاغ من ولي الأمر عن مشكلة تخص طبيباً (سلوك، معلومات غير صحيحة، عدم حضور، أو سبب اخر).
/// A parent-submitted problem report about a doctor — reviewed by the admin.
/// </summary>
public class ProblemReport
{
    public Guid Id { get; set; }

    // ── من أبلغ ──
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    // ── الطبيب المُبلَّغ عنه ──
    public Guid SpecialistId { get; set; }
    public Specialist Specialist { get; set; } = null!;

    /// <summary>
    /// الحجز/الجلسة المرتبطة بالبلاغ — اختياري (يُملأ عند فتح البلاغ من جلسة محددة).
    /// null عند الإبلاغ من ملف الطبيب دون جلسة بعينها.
    /// </summary>
    public Guid? BookingId { get; set; }
    public Booking? Booking { get; set; }

    /// <summary>نوع المشكلة الرئيسية (مطلوب).</summary>
    public ProblemReportCategory Category { get; set; }

    /// <summary>وصف المشكلة الحالية (اختياري).</summary>
    public string? Description { get; set; }

    /// <summary>حالة معالجة البلاغ من جانب الأدمن.</summary>
    public ProblemReportStatus Status { get; set; } = ProblemReportStatus.New;

    /// <summary>ملاحظة الأدمن عند تحديث حالة البلاغ (اختياري).</summary>
    public string? AdminNote { get; set; }

    /// <summary>وقت آخر مراجعة/تحديث للحالة من الأدمن (UTC). null قبل أي مراجعة.</summary>
    public DateTime? ReviewedAt { get; set; }

    /// <summary>مُعرّف مستخدم الأدمن الذي راجع البلاغ.</summary>
    public Guid? ReviewedByUserId { get; set; }

    public DateTime CreatedAt { get; set; }
}
