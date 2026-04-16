using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.ChildTask;

/// <summary>
/// يُرسل كـ multipart/form-data — جميع الحقول اختيارية تماماً
///
/// كل الحقول من نوع string? لضمان قبول القيمة الفارغة في form-data دون خطأ model binding.
/// السلوك: null أو فارغ = تُبقى القيمة الحالية دون أي تغيير.
/// أرسل فقط الحقول التي تريد تعديلها.
///
/// منطق الصورة/التسجيل:
///   - أرسل ملفاً جديداً                         → رفع + استبدال القديم
///   - أرسل ExistingXxxUrl برابط القديم (بدون ملف) → احتفاظ بالقديم
///   - أرسل ExistingXxxUrl فارغ (بدون ملف)        → حذف القديم من Azure
///   - لا ملف + لا ExistingXxxUrl                → لا تغيير
/// </summary>
public class UpdateChildTaskRequestDto
{
    /// <summary>العنوان — null أو فارغ = لا تغيير</summary>
    public string? Title { get; set; }

    // ── Task Image ────────────────────────────────────────────────────────────
    public IFormFile? TaskImage { get; set; }

    /// <summary>
    /// رابط الصورة الحالية:
    ///   - برابط القديم = الاحتفاظ به
    ///   - "" (فارغ) = حذف الصورة الحالية
    ///   - null (لم يُرسل) = لا تغيير
    /// </summary>
    public string? ExistingTaskImageUrl { get; set; }

    // ── Recording ─────────────────────────────────────────────────────────────
    public IFormFile? Recording { get; set; }

    /// <summary>
    /// رابط التسجيل الحالي (نفس منطق الصورة أعلاه)
    /// </summary>
    public string? ExistingRecordingUrl { get; set; }

    // ── Scalar fields — string? بدلاً من value types لقبول الفارغ ─────────────

    /// <summary>عدد النجوم (0-100) — null أو فارغ = لا تغيير</summary>
    public string? Stars { get; set; }

    /// <summary>تاريخ البدء ISO 8601 — null أو فارغ = لا تغيير</summary>
    public string? StartDate { get; set; }

    /// <summary>تاريخ الانتهاء ISO 8601 — null أو فارغ = لا تغيير</summary>
    public string? DueDate { get; set; }

    // ── Children ──────────────────────────────────────────────────────────────

    /// <summary>
    /// معرفات الأطفال (Guid strings) — حقول متعددة:
    ///   selectedChildIds=id1&amp;selectedChildIds=id2
    ///   - قائمة غير فارغة = استبدال القائمة الحالية
    ///   - فارغة أو null   = لا تغيير
    /// </summary>
    public List<string>? SelectedChildIds { get; set; }

    // ── Recurrence ────────────────────────────────────────────────────────────

    /// <summary>
    /// "true" → تفعيل التكرار (يجب إرسال RepeatDays)
    /// "false" → إلغاء التكرار
    /// null أو فارغ → لا تغيير
    /// </summary>
    public string? IsRecurring { get; set; }

    /// <summary>أيام التكرار بفاصلة: "saturday,thursday" — null أو فارغ = لا تغيير</summary>
    public string? RepeatDays { get; set; }

    /// <summary>وقت التكرار HH:mm — null أو فارغ = لا تغيير</summary>
    public string? RepeatTime { get; set; }
}
