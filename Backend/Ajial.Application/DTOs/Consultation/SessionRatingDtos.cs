namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// تقييم الجلسة (المرحلة الثامنة) — استبيان ولي الأمر بعد اكتمال الجلسة
// ============================================================

/// <summary>طلب إرسال تقييم الجلسة (الاستبيان: نجوم + سؤالين).</summary>
public class SubmitSessionRatingRequest
{
    /// <summary>تقييم الجلسة بالنجوم من 1 الى 5.</summary>
    public int Rating { get; set; }

    /// <summary>هل ستعاود طلب الجلسة مرة اخرى؟ true = نعم عند الحاجة، false = لا، جلسة ضعيفة ولم نستفد منها.</summary>
    public bool WouldBookAgain { get; set; }

    /// <summary>هل واجهت اى مشكلة اثناء الجلسة او الحجز؟</summary>
    public bool HadIssue { get; set; }

    /// <summary>وصف المشكلة — مطلوب فقط عندما يكون HadIssue = true.</summary>
    public string? IssueDescription { get; set; }
}

/// <summary>حالة تقييم الجلسة (هل قُيّمت + تفاصيل التقييم + رصيد النجوم).</summary>
public class SessionRatingResponse
{
    public Guid BookingId { get; set; }

    /// <summary>هل تم تقييم هذه الجلسة من قبل.</summary>
    public bool HasRated { get; set; }

    /// <summary>هل يمكن تقييم الجلسة الان (مكتملة ولم تُقيَّم بعد).</summary>
    public bool CanRate { get; set; }

    // ── تفاصيل التقييم (تُملأ فقط عند HasRated = true) ──
    public int? Rating { get; set; }
    public bool? WouldBookAgain { get; set; }
    public bool? HadIssue { get; set; }
    public string? IssueDescription { get; set; }
    public DateTime? RatedAt { get; set; }

    /// <summary>عدد نجوم المكافأة الممنوحة مقابل التقييم (250).</summary>
    public int StarsAwarded { get; set; }

    /// <summary>رصيد نجوم ولي الأمر الإجمالي بعد إضافة المكافأة.</summary>
    public int NewStarsBalance { get; set; }
}
