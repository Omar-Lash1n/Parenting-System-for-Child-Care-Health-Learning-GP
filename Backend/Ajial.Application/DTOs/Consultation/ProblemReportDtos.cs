namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// الإبلاغ عن مشكلة — جانب ولي الأمر (بلاغ عن طبيب)
// ============================================================

/// <summary>خيار من خيارات نوع المشكلة الرئيسية (لقائمة الاختيار في الواجهة).</summary>
public class ProblemCategoryOption
{
    /// <summary>القيمة الرقمية لنوع المشكلة (تُرسل في طلب الإبلاغ).</summary>
    public int Value { get; set; }

    /// <summary>المفتاح النصي الثابت.</summary>
    public string Key { get; set; } = string.Empty;

    /// <summary>التسمية العربية المعروضة لولي الأمر.</summary>
    public string LabelAr { get; set; } = string.Empty;
}

/// <summary>طلب إرسال بلاغ عن مشكلة تخص طبيباً.</summary>
public class SubmitProblemReportRequest
{
    /// <summary>نوع المشكلة الرئيسية (1=سلوك، 2=معلومات غير صحيحة، 3=عدم حضور، 4=سبب اخر) — مطلوب.</summary>
    public int Category { get; set; }

    /// <summary>وصف المشكلة الحالية (اختياري).</summary>
    public string? Description { get; set; }

    /// <summary>الحجز/الجلسة المرتبطة بالبلاغ — اختياري (عند الإبلاغ من جلسة محددة).</summary>
    public Guid? BookingId { get; set; }
}

/// <summary>استجابة بعد إرسال البلاغ (تأكيد التسجيل).</summary>
public class ProblemReportResponse
{
    public Guid Id { get; set; }
    public Guid SpecialistId { get; set; }
    public Guid? BookingId { get; set; }

    public int Category { get; set; }
    public string CategoryKey { get; set; } = string.Empty;
    public string CategoryAr { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}
