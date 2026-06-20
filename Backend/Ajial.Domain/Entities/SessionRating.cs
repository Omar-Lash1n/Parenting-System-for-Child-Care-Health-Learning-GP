namespace Ajial.Domain.Entities;

/// <summary>
/// تقييم ولي الأمر لجلسة استشارة بعد اكتمالها (استبيان: نجوم + سؤالين) — تقييم واحد لكل حجز.
/// A parent's rating survey for a completed consultation booking — one rating per booking.
/// مقابل إكمال الاستبيان يحصل ولي الأمر على نقاط نجوم تُضاف الى رصيده.
/// </summary>
public class SessionRating
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    /// <summary>تقييم الجلسة بالنجوم من 1 الى 5.</summary>
    public int Rating { get; set; }

    /// <summary>هل ستعاود طلب الجلسة مرة اخرى؟ true = نعم عند الحاجة، false = لا، جلسة ضعيفة ولم نستفد منها.</summary>
    public bool WouldBookAgain { get; set; }

    /// <summary>هل واجهت اى مشكلة اثناء الجلسة او الحجز؟</summary>
    public bool HadIssue { get; set; }

    /// <summary>وصف المشكلة الحالية — يُملأ فقط عندما يكون HadIssue = true.</summary>
    public string? IssueDescription { get; set; }

    /// <summary>عدد نجوم المكافأة المُضافة لرصيد ولي الأمر مقابل التقييم (لقطة وقت التقييم).</summary>
    public int StarsAwarded { get; set; }

    public DateTime CreatedAt { get; set; }
}
