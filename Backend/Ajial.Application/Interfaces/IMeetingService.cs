namespace Ajial.Application.Interfaces;

/// <summary>
/// خدمة إنشاء روابط الاجتماعات المرئية (Google Meet) لجلسات الكشف اون لاين.
/// التجريد يفصل منطق الحجز عن آلية المصادقة المستخدمة لتوليد الرابط.
/// </summary>
public interface IMeetingService
{
    /// <summary>
    /// ينشئ اجتماع Google Meet جديداً في الفترة المحددة ويُرجع رابط الانضمام ومعرّف الحدث.
    /// </summary>
    /// <param name="title">عنوان الجلسة (يظهر في التقويم).</param>
    /// <param name="description">وصف اختياري للجلسة.</param>
    /// <param name="startEgyptLocal">وقت بداية الجلسة بتوقيت مصر المحلي (UTC+2).</param>
    /// <param name="endEgyptLocal">وقت نهاية الجلسة بتوقيت مصر المحلي (UTC+2).</param>
    Task<MeetingInfo> CreateMeetingAsync(
        string title,
        string? description,
        DateTime startEgyptLocal,
        DateTime endEgyptLocal,
        CancellationToken cancellationToken = default);
}

/// <summary>نتيجة إنشاء الاجتماع.</summary>
public record MeetingInfo(string JoinUrl, string EventId);
